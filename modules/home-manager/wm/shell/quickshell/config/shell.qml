//@ pragma UseQApplication
import Quickshell
import qs.bar
import qs.notifications
import qs.recorder

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Popups {}
    Center {}
    RecordMenu {}
}
