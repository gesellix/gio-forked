// SPDX-License-Identifier: Unlicense OR MIT

package app

import (
	"fmt"
	"sync"
	"sync/atomic"
)

// DiagDrawInBackground lets the iOS driver draw while the program is in the
// background. Test only, never to be sent upstream.
var DiagDrawInBackground atomic.Bool

var diag struct {
	mu    sync.Mutex
	trace func(string)
	early []string
}

// DiagSetTrace sets the function that receives what the iOS driver does, and
// gives it what happened so far. It may be called on the main thread and on the
// Metal completion thread. Test only.
func DiagSetTrace(f func(string)) {
	diag.mu.Lock()
	early := diag.early
	diag.trace, diag.early = f, nil
	diag.mu.Unlock()
	for _, s := range early {
		f(s)
	}
}

func diagTrace(format string, args ...any) {
	s := fmt.Sprintf(format, args...)
	diag.mu.Lock()
	f := diag.trace
	if f == nil {
		diag.early = append(diag.early, s)
	}
	diag.mu.Unlock()
	if f != nil {
		f(s)
	}
}
