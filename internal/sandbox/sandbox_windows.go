//go:build windows
// +build windows

package sandbox

import (
	"os/exec"
	"strconv"
	"syscall"
)

// setupSysProcAttr sets up the process attributes to create a new process group on Windows
func setupSysProcAttr(cmd *exec.Cmd) {
	cmd.SysProcAttr = &syscall.SysProcAttr{
		CreationFlags: syscall.CREATE_NEW_PROCESS_GROUP,
	}
}

// killProcessGroup kills the entire process group on Windows
func killProcessGroup(cmd *exec.Cmd) {
	if cmd.Process != nil {
		// On Windows, we can use taskkill to kill the process tree
		killCmd := exec.Command("taskkill", "/T", "/F", "/PID", strconv.Itoa(cmd.Process.Pid))
		_ = killCmd.Run()
	}
}
