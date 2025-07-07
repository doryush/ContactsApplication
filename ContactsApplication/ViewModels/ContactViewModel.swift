//
//  ContactViewModel.swift
//  ContactsApplication
//
//  Created by Doryush Normatov on 7/3/25.
//
import Foundation
import Contacts

struct Contact {
    let name: String
    let phone: String
    let extraPhonesCount: Int
}


struct Section {
    let letter: String
    let contacts: [Contact]
}

final class ContactViewModel {

    var onUpdate: (([Section]) -> Void)?
    var onPermissionDenied: (() -> Void)?
    var onError: ((Error) -> Void)?

    private let store = CNContactStore()

    func load() {
        checkPermission()
    }


    func refresh() {
        load()
    }

    private func checkPermission() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .notDetermined:
            onPermissionDenied?()
            store.requestAccess(for: .contacts) { [weak self] granted, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.onError?(error)
                    } else if granted {
                        self?.reloadSections()
                    } else {
                        self?.onPermissionDenied?()
                    }
                }
            }
        case .authorized:
            reloadSections()
        default:
            onPermissionDenied?()
        }
    }

    private func reloadSections() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let allContacts = self.fetchContacts()
            let grouped = Dictionary(grouping: allContacts) { contact in
                String(contact.name.first ?? "#").uppercased()
            }
            let sections = grouped
                .map { Section(letter: $0.key, contacts: $0.value) }
                .sorted { $0.letter < $1.letter }
            
            DispatchQueue.main.async {
                self.onUpdate?(sections)
            }
        }
    }

    private func fetchContacts() -> [Contact] {
        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor
        ]
        let request = CNContactFetchRequest(keysToFetch: keys)
        var results: [Contact] = []
        do {
            try store.enumerateContacts(with: request) { cn, _ in
                let name: String
                if !cn.givenName.isEmpty || !cn.familyName.isEmpty {
                    name = "\(cn.givenName) \(cn.familyName)"
                } else {
                    name = cn.organizationName
                }
                let phones = cn.phoneNumbers.map { $0.value.stringValue }
                if let first = phones.first {
                    results.append(Contact(
                        name: name,
                        phone: first,
                        extraPhonesCount: max(0, phones.count - 1)
                    ))
                }
            }
        } catch {
            onError?(error)
        }
        return results
    }
}
