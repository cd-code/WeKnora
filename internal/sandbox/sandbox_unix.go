//go:build !windows
// +build !windows

package sandbox

import (
	"os/exec"
	"syscall"
)

// setupSysProcAttr sets up the process attributes to create a new process group on Unix-like systems
func setupSysProcAttr(cmd *exec.Cmd) {
	cmd.SysProcAttr = &syscall.SysProcAttr{
		Setpgid: true,
	}
}

// killProcessGroup kills the entire process group by sending SIGKILL to the negative PID on Unix-like systems
func killProcessGroup(cmd *exec.Cmd) {
	if cmd.Process != nil {
		_ = syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL)
	}
}
