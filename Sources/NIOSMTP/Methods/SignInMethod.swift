public enum SignInMethod {
    case anonymous
    case credentials(username: String, password: String)
}
