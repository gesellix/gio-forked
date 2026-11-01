// SPDX-License-Identifier: Unlicense OR MIT

package app

import "C"

//export gio_diagTrace
func gio_diagTrace(s *C.char) {
	diagTrace("%s", C.GoString(s))
}
