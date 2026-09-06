package app

import (
	"context"
	"debug/elf"
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// imageChecks consumes the trusted archives built by our Nix image derivations.
// It tests the CLI actually shipped in each image, without a container daemon.
func (a *App) imageChecks(ctx context.Context, archives []string) error {
	for i, pool := range []string{"go", "node24", "docker", "nix"} {
		if err := a.imageCheck(ctx, archives[i], pool); err != nil {
			return fmt.Errorf("%s image: %w", pool, err)
		}
	}
	return nil
}

func (a *App) imageCheck(ctx context.Context, archive, pool string) (result error) {
	work, err := privateDir("acs-image-check-")
	if err != nil {
		return err
	}
	defer func() {
		// Nix store directories extracted inside this temporary root are read-only.
		chmodErr := filepath.WalkDir(work, func(path string, d fs.DirEntry, err error) error {
			if err == nil && d.IsDir() {
				return os.Chmod(path, 0700)
			}
			return err
		})
		result = errors.Join(result, chmodErr, removePrivate(work))
	}()
	unpack, root := filepath.Join(work, "archive"), filepath.Join(work, "root")
	for _, path := range []string{unpack, filepath.Join(root, "dev"), filepath.Join(root, "proc")} {
		if err = os.MkdirAll(path, 0755); err != nil {
			return err
		}
	}
	if err = a.command(ctx, "tar", "-xf", archive, "-C", unpack, "--no-same-owner"); err != nil {
		return err
	}
	b, err := os.ReadFile(filepath.Join(unpack, "manifest.json"))
	if err != nil {
		return err
	}
	var manifest []struct{ Layers []string }
	if json.Unmarshal(b, &manifest) != nil || len(manifest) != 1 || len(manifest[0].Layers) == 0 {
		return errors.New("expected one Docker archive manifest with layers")
	}
	for _, layer := range manifest[0].Layers {
		if !filepath.IsLocal(layer) {
			return errors.New("unsafe archive layer path")
		}
		path, err := filepath.EvalSymlinks(filepath.Join(unpack, layer))
		if err != nil {
			return err
		}
		relative, err := filepath.Rel(unpack, path)
		if err != nil || !filepath.IsLocal(relative) {
			return errors.New("layer escapes archive directory")
		}
		if err = a.command(ctx, "tar", "-xf", path, "-C", root, "--no-same-owner"); err != nil {
			return err
		}
	}
	// Clear host credentials and Nix/Go settings before entering the extracted root.
	args := []string{"env", "-i", "PATH=" + os.Getenv("PATH"), "HOME=/data/home", "proot", "-0", "-r", root, "-b", "/dev", "-b", "/proc", "-w", "/data",
		"/bin/env", "PATH=/bin", "HOME=/data/home", "NIX_REMOTE=local", "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt", "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt", "PKG_CONFIG_PATH=/lib/pkgconfig:/share/pkgconfig"}
	if pool == "docker" {
		// PRoot cannot emulate crun's sealed self-reexecution. Check dependency
		// resolution inside the image, then execute the actual extracted binary
		// natively so its normal executable-sealing protection remains intact.
		resolved, err := a.capture(ctx, append(append([]string{}, args...), "readlink", "-f", "/bin/crun")...)
		if err != nil {
			return err
		}
		binary := strings.TrimSpace(string(resolved))
		if !strings.HasPrefix(binary, "/nix/store/") || !strings.HasSuffix(binary, "/bin/crun") || filepath.Clean(binary) != binary {
			return errors.New("unexpected crun path in image")
		}
		extracted := filepath.Join(root, strings.TrimPrefix(binary, "/"))
		executable, err := elf.Open(extracted)
		if err != nil {
			return err
		}
		section := executable.Section(".interp")
		var interpreter []byte
		if section != nil {
			interpreter, err = section.Data()
		}
		err = errors.Join(err, executable.Close())
		if err != nil {
			return err
		}
		if len(interpreter) > 0 {
			loader := strings.TrimRight(string(interpreter), "\x00")
			if _, err = a.capture(ctx, append(append([]string{}, args...), loader, "--list", binary)...); err != nil {
				return fmt.Errorf("crun image dependencies: %w", err)
			}
		}
		short, cancel := context.WithTimeout(ctx, 10*time.Second)
		err = a.command(short, extracted, "--version")
		cancel()
		if err != nil {
			return err
		}
		a.message("PASS: extracted crun binary (native execution) and image dynamic dependencies (PRoot)")
	}
	run := func(command ...string) error {
		return a.command(ctx, append(append([]string{}, args...), command...)...)
	}
	if err = run("/usr/bin/env", "bash", "-c", "echo env-shebang-ok"); err != nil {
		return err
	}
	for _, command := range [][]string{{"forgejo-runner", "--version"}, {"acs", "--help"}, {"acs", "workflow", "image-test", pool}} {
		if err = run(command...); err != nil {
			return err
		}
	}
	for _, item := range []struct {
		args []string
		want string
	}{
		{[]string{"forgejo-runner", "one-job", "--help"}, "Run only one job"},
		{[]string{"forgejo-runner", "register", "--help"}, "--ephemeral"},
	} {
		b, err = a.capture(ctx, append(append([]string{}, args...), item.args...)...)
		if err != nil {
			return err
		}
		if !strings.Contains(string(b), item.want) {
			return errors.New("runner lacks required ephemeral one-job support")
		}
	}
	if pool == "nix" {
		for _, command := range [][]string{{"direnv", "version"}, {"cachix", "--version"}, {"attic", "--version"}} {
			if err = run(command...); err != nil {
				return err
			}
		}
	}
	if err = run("test", "-s", "/etc/ssl/certs/ca-bundle.crt"); err != nil {
		return err
	}
	a.message("PASS: %s image and embedded CLI", pool)
	return nil
}

func (a *App) builderBinaries(ctx context.Context) error {
	for _, tool := range []string{"buildah", "skopeo"} {
		short, cancel := context.WithTimeout(ctx, 10*time.Second)
		err := a.command(short, tool, "--version")
		cancel()
		if err != nil {
			return err
		}
	}
	for _, path := range []string{"/etc/containers/policy.json", "/etc/containers/storage.conf"} {
		b, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		if len(b) == 0 {
			return fmt.Errorf("empty %s", path)
		}
		if strings.HasSuffix(path, "storage.conf") && !strings.Contains(string(b), "vfs") {
			return errors.New("builder must use vfs storage")
		}
	}
	if _, err := os.Stat("/var/run/docker.sock"); !os.IsNotExist(err) {
		return errors.New("unexpected Docker socket or inspection failure")
	}
	a.message("PASS: Buildah/Skopeo and builder configuration (crun checked by outer image test; native build/push remains separate)")
	return nil
}
