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
struct Entry : Hashable, CustomStringConvertible {
    static func == (lhs: Entry, rhs: Entry) -> Bool {
        return lhs.key == rhs.key && lhs.value == rhs.value
    }
    
    init(_ t: String, _ u: String) {
        key = t
        value = u
    }
    
    let key : String
    let value : String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(value)
    }
    
    public var description: String { return "\(key):\(value)" }
}

// Contact interface
struct Contact : Hashable{
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        return lhs.contact == rhs.contact
    }
    
    var contact: CNMutableContact
    var data: [Entry] = []
    var name: String {
        get {
            return CNContactFormatter.string(from: contact, style: .fullName) ?? "Unnamed"
        }
    }
    var allData: [Entry] = []
    
    init() {
        self.contact = CNMutableContact()
        let saveRequest = CNSaveRequest()
        saveRequest.add(contact, toContainerWithIdentifier: nil)
        try! CNContactStore().execute(saveRequest)
        self.data = []
        allData = []
    }
    
    init(_ contact: CNMutableContact) {
        self.contact = contact
        fetchData();
    }
    
    func update() {
        contact.instantMessageAddresses = []
        for entry in data {
            contact.instantMessageAddresses.append(CNLabeledValue(label: entry.key, value: CNInstantMessageAddress(username: entry.value, service: entry.key)))
        }
        let saveRequest = CNSaveRequest()
        saveRequest.update(contact)
        try! CNContactStore().execute(saveRequest)
    }
    
    func delete() {
        let saveRequest = CNSaveRequest()
        saveRequest.delete(contact)
        try! CNContactStore().execute(saveRequest)
    }
    
    mutating func replace(_ e1: Entry, _ e2: Entry) {
        for i in 0..<data.count {
            if (data[i] == e1) {
                data[i] = e2
                break;
            }
        }
        update();
    }
    
    mutating func fetch() {
        contact = try! CNContactStore().unifiedContact(withIdentifier: contact.identifier, keysToFetch: keys).mutableCopy() as! CNMutableContact
        fetchData();
    }
    
    mutating func fetchData() {
        self.data = []
        self.allData = []
        
        
        
        for address in contact.instantMessageAddresses {
            let e = Entry(address.value.service, address.value.username)
            self.data.append(e)
            self.allData.append(e)
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(contact)
    }
}

// Main view
struct ContentView: View {
    
    @State var contacts: [Contact] = [];
    @State var edits: [Contact] = []
    @State var searchText: String = "";
    @State var currentPage = 0
    
    
    func delete(at offsets: IndexSet) {
        for i in offsets {
    
            contacts[i].delete()
            contacts.remove(at: i)
        }
    }
    
    var body: some View {
        TabView {
            NavigationView {
                VStack {
                    SearchBar(text: $searchText)
                    List {
                        ForEach(contacts, id: \.self) {contact in
                            NavigationLink(destination: ContactDetail(contact).navigationBarItems(trailing: Button("Edit"){
                                self.edits.append(contact)
                            })) {
                                Text(contact.name)
                            }
                        }.onDelete(perform: delete)
                    }
                }.navigationBarItems(trailing:
                    Button(action: {
                        let contact = Contact()
                        self.edits.append(contact)
                        self.contacts.insert(contact, at: 0)
                    }) {
                        Image(systemName: "plus").imageScale(.large).padding()
                }).navigationBarTitle(Text("Search"))
            }.tabItem{
                Image(systemName: "magnifyingglass")
            }
            ForEach(0..<self.edits.count, id: \.self) { edit in
                NavigationView {
                    List {
                        ForEach(0..<self.edits[edit].data.count, id: \.self) {entry in
                            TextField("", text: $edits[edit].data[entry].key)
                        }
                    }.navigationBarTitle(Text(self.edits[edit].name),displayMode: .inline).navigationBarItems(trailing:
                        Button(action: {
                            let contact = Contact()
                            self.edits.append(contact)
                            self.contacts.insert(contact, at: 0)
                        }) {
                            Image(systemName: "plus").imageScale(.large).padding()
                    })
                }.tabItem {
                    Image(systemName: "circle.fill").imageScale(.small)
                }
            }
        }.onAppear {
            let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
            try! CNContactStore().enumerateContacts(with: request) {
                (contact, stop) in
                self.contacts.insert(Contact(contact.mutableCopy() as! CNMutableContact), at: 0)
            }
        }
    }
}

/*struct ContactField : View {
    let viewModel: Contact
    @State private var entries: [Entry] = []
    var didUpdateEntries: [Entry] -> ()
    
    init(_ viewModel: Contact, _ didUpdateText: @escaping (String, String)->()) {
        self.viewModel = viewModel
        self.didUpdateText = didUpdateText
    }

    var body: some View {
        List {
            ForEach (entries, id: \.self) {entry in
                EntryField(entry) {k,v in
                    
                }
            }
        }.onAppear() {
            self.entries = self.viewModel.data
        }
    }
}*/

struct EntryField : View {
    let viewModel: Entry
    @State private var key: String = ""
    @State private var value: String = ""
    var didUpdateText: (String, String) -> ()
    
    init(_ viewModel: Entry, _ didUpdateText: @escaping (String, String)->()) {
        self.viewModel = viewModel
        self.didUpdateText = didUpdateText
    }

    var body: some View {
        HStack {
            TextField(viewModel.key, text: $key, onCommit: {
                self.didUpdateText(self.key, self.value)
            }).onAppear {
                self.key = self.viewModel.key
            }
            TextField(viewModel.value, text: $value, onCommit: {
                self.didUpdateText(self.key, self.value)
            }).onAppear {
                self.value = self.viewModel.value
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

// Shows the detail of a contact
struct ContactDetail : View {
    var contact: Contact
    
    
    init(_ contact: Contact) {
        self.contact = contact;
    }
    
    var body: some View {
        List {
            ForEach (contact.data, id: \.self) {entry in
                HStack {
                    Text(entry.key)
                    Text(entry.value)
                }
            }
        }.navigationBarTitle(Text(contact.name),displayMode: .inline)
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

struct PageViewController: UIViewControllerRepresentable {
    var controllers: [UIViewController]

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal)

        return pageViewController
    }

    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        pageViewController.setViewControllers(
            [controllers[0]], direction: .forward, animated: true)
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource {
        var parent: PageViewController

        init(_ pageViewController: PageViewController) {
            self.parent = pageViewController
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController) -> UIViewController?
        {
            guard let index = parent.controllers.firstIndex(of: viewController) else {
                return nil
            }
            if index == 0 {
                return parent.controllers.last
            }
            return parent.controllers[index - 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController) -> UIViewController?
        {
            guard let index = parent.controllers.firstIndex(of: viewController) else {
                return nil
            }
            if index + 1 == parent.controllers.count {
                return parent.controllers.first
            }
            return parent.controllers[index + 1]
        }
    }
}
