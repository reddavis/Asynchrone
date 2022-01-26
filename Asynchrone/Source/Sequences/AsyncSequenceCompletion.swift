/// Describes how an async sequence has completed.
public enum AsyncSequenceCompletion<Failure: Error> {
    
    /// The async sequence finished normally.
    case finished
    
    /// The async sequence stopped emitting elements due to
    /// the indicated error.
    case failure(Failure)
}
