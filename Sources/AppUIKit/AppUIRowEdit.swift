/// What a person typed into an `AppUIRowView` that can be edited, said in the words of the keys and not as a change of text: the owner of the rows knows
/// where in its text the caret or the selection is, and what each of these does there.
public enum AppUIRowEdit: Equatable, Sendable {
    /// Text typed or pasted, which replaces the selection or is put at the caret.
    case insert(String)
    /// The key that takes out what is before the caret, or the selection.
    case deleteBackward
    /// The key that takes out what is after the caret, or the selection.
    case deleteForward
    /// The return key.
    case newline
}
