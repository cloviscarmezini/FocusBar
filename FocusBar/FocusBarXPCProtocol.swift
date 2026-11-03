import Foundation

// O @objc é obrigatório para que a comunicação XPC funcione no macOS
@objc protocol FocusBarXPCProtocol {
    func applyBlocklist(domains: [String], withReply reply: @escaping (Bool) -> Void)
}
