//
//  ContentView.swift
//  thymesia
//
//  Created by Chase Norman on 10/25/19.
//  Copyright © 2019 Chase Norman. All rights reserved.
//

import SwiftUI
import Contacts
import ContactsUI

let keys = [CNContactInstantMessageAddressesKey,CNContactGivenNameKey,CNContactTypeKey,CNContactDatesKey,CNContactBirthdayKey,CNContactNicknameKey,CNContactRelationsKey,CNContactIdentifierKey,CNContactJobTitleKey,CNContactImageDataKey,CNContactFamilyNameKey,CNContactMiddleNameKey,CNContactNamePrefixKey,CNContactNameSuffixKey,CNContactPhoneNumbersKey,CNContactUrlAddressesKey,CNContactDepartmentNameKey,CNContactEmailAddressesKey,CNContactSocialProfilesKey,CNContactPostalAddressesKey,CNContactOrganizationNameKey,CNContactPhoneticGivenNameKey,CNContactImageDataAvailableKey,CNContactPhoneticFamilyNameKey,CNContactPhoneticMiddleNameKey,CNContactPreviousFamilyNameKey,CNContactThumbnailImageDataKey,CNContactNonGregorianBirthdayKey,CNContactPhoneticOrganizationNameKey] as [CNKeyDescriptor]

let emptyContact = Contact(CNMutableContact())


// Hashable tuple of length 2.
struct Entry<T:Hashable,U:Hashable> : Hashable {
    static func == (lhs: Entry<T, U>, rhs: Entry<T, U>) -> Bool {
        return lhs.values == rhs.values
    }
    
    init(_ t: T, _ u: U) {
        values = (t, u)
    }
    
    let values : (T, U)
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(values.0)
        hasher.combine(values.1)
    }
}

// Contact interface
struct Contact : Hashable{
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        return lhs.contact == rhs.contact
    }
    
    var contact: CNMutableContact
    var data: [Entry<String, String>] = []
    
    init() {
        self.contact = CNMutableContact()
        CNSaveRequest().add(contact, toContainerWithIdentifier: nil)
        self.data = []
    }
    
    init(_ contact: CNMutableContact) {
        self.contact = contact
        fetchData();
    }
    
    func add(key: String, value: String) {
        contact.instantMessageAddresses.append(CNLabeledValue<CNInstantMessageAddress>.init(label: key, value: CNInstantMessageAddress.init(username: value, service: key)))
        update();
    }
    
    func update() {
        CNSaveRequest().update(contact)
    }
    
    mutating func fetch() {
        contact = try! CNContactStore().unifiedContact(withIdentifier: contact.identifier, keysToFetch: keys).mutableCopy() as! CNMutableContact
        fetchData();
    }
    
    mutating func fetchData() {
        self.data = []
        for address in contact.instantMessageAddresses {
            self.data.append(Entry(address.value.service, address.value.username))
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(contact)
    }
}

// Main view
struct ContentView: View {
    
    var contacts: [Contact] = [];
    
    @State var edits: [Contact] = []
    @State var searchText: String = "";
    
    init() {
        var c: [Contact] = []
        
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        try! CNContactStore().enumerateContacts(with: request) {
            (contact, stop) in
            c.append(Contact(contact.mutableCopy() as! CNMutableContact))
        }
        contacts = c;
    }
    
    var body: some View {
        TabView {
            NavigationView {
                VStack {
                    SearchBar(text: $searchText)
                    List {
                        ForEach(contacts, id: \.self) {contact in
                            NavigationLink(destination: ContactDetail(contact)) {
                                Text(String(describing: contact.data))
                            }
                        }
                    }
                }.navigationBarItems(trailing:
                    Button(action: {self.edits.insert(Contact(), at: 0)}) {
                    Image(systemName: "plus").imageScale(.large)
                }).navigationBarTitle(Text("Search"))
            }.tabItem{
                Image(systemName: "magnifyingglass")
            }
            ForEach(edits, id: \.self) { edit in
                CreateView(contact: edit).tabItem {
                    Image(systemName: "circle.fill")
                }
            }
        }
    }
}

// Necessary for testing
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// Where our contact is created.
struct CreateView : View {
    let c: Contact;
    @State var contact: Contact = emptyContact;
    
    init(contact: Contact) {
        c = contact;
    }
    
    var body : some View {
        List {
            ForEach(contact.data, id: \.self) {elem in
                Text(String(describing: elem))
            }
        }.onAppear {
            self.contact = self.c;
        }
    }
}

// Shows the detail of a contact
struct ContactDetail : View {
    var contact: Contact
    
    
    init(_ contact: Contact) {
        self.contact = contact;
    }
    
    var body: some View {
        Text("hi")
    }
}

// Ignore. Copied from stackoverflow
struct SearchBar: UIViewRepresentable {

    @Binding var text: String

    class Coordinator: NSObject, UISearchBarDelegate {

        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
    }
    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.autocapitalizationType = .none
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
    }
}
