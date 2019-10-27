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

let identifier = [CNContactIdentifierKey] as [CNKeyDescriptor];

let emptyEntry = Entry("","")


// Hashable tuple of length 2.
struct Entry : Hashable, CustomStringConvertible, Identifiable {
    var id = UUID()
    
    static func == (lhs: Entry, rhs: Entry) -> Bool {
        return lhs.key == rhs.key && lhs.value == rhs.value
    }
    
    init(_ t: String, _ u: String) {
        key = t
        value = u
    }
    
    var key : String
    var value : String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(value)
    }
    
    public var description: String { return "\(key):\(value)" }
}

// Main view
struct ContentView: View {
    
    @State var contacts: [String] = [];
    @State var edits: [String] = []
    @State var searchText: String = "";
    @State var currentPage = 0
    
    
    func delete(at offsets: IndexSet) {
        for i in offsets {
            let x = (try! CNContactStore().unifiedContact(withIdentifier: contacts[i], keysToFetch: keys).mutableCopy() as! CNMutableContact)
            let save = CNSaveRequest()
            save.delete(x);
            try! CNContactStore().execute(save);
    
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
                                Text(contact)
                            }
                        }.onDelete(perform: delete)
                    }
                }.navigationBarItems(trailing:
                    Button(action: {
                        let c = CNMutableContact();
                        let save = CNSaveRequest();
                        save.add(c, toContainerWithIdentifier: nil)
                        try! CNContactStore().execute(save)
                        
                        self.edits.append(c.identifier)
                        self.contacts.insert(c.identifier, at: 0)
                    }) {
                        Image(systemName: "plus").imageScale(.large).padding()
                }).navigationBarTitle(Text("Search"))
            }.tabItem{
                Image(systemName: "magnifyingglass")
            }
            ForEach(edits, id: \.self) { edit in
                NavigationView {
                    ContactField(edit).navigationBarTitle(Text(edit),displayMode: .inline).navigationBarItems(trailing:
                        Button(action: {
                            let c = CNMutableContact();
                            let save = CNSaveRequest();
                            save.add(c, toContainerWithIdentifier: nil)
                            try! CNContactStore().execute(save)
                            
                            self.edits.append(c.identifier)
                            self.contacts.insert(c.identifier, at: 0)
                        }) {
                            Image(systemName: "plus").imageScale(.large).padding()
                    })
                }.tabItem {
                    Image(systemName: "circle.fill").imageScale(.small)
                }
            }
        }.onAppear {
            self.refreshContacts()
        }
    }
    
    func refreshContacts() {
        contacts = []
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        try! CNContactStore().enumerateContacts(with: request) {
            (contact, stop) in
            self.contacts.insert(contact.identifier, at: 0)
        }
    }
    
    func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
}

struct ContactField : View {
    let viewModel: String
    @State private var entries: [Entry] = Array<Entry>(repeating: emptyEntry, count: 50)
    @State private var len = 0;
    
    init(_ viewModel: String) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            ForEach (entries.indices) {index in
                if (index < self.len) {
                    HStack {
                        TextField("", text: self.$entries[index].key, onCommit: {
                            self.update();
                        })
                        TextField("", text: self.$entries[index].value, onCommit: {
                            self.update();
                        })
                    }
                }
            }
        }.onAppear() {
            let x = try! CNContactStore().unifiedContact(withIdentifier: self.viewModel, keysToFetch: keys)
            let attr = x.instantMessageAddresses;
            
            for i in 0..<attr.count {
                self.entries[i] = Entry(attr[i].value.service, attr[i].value.username)
            }
            self.len = attr.count
        }
    }
    
    func update() {
        let x = (try! CNContactStore().unifiedContact(withIdentifier: self.viewModel, keysToFetch: keys).mutableCopy() as! CNMutableContact)
        x.instantMessageAddresses = []
        
        for i in self.entries {
            x.instantMessageAddresses.append(CNLabeledValue<CNInstantMessageAddress>(label: i.key, value: CNInstantMessageAddress(username: i.value, service: i.key)))
        }
        
        let save = CNSaveRequest()
        save.update(x);
        try! CNContactStore().execute(save);
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
    let viewModel: String
    @State private var entries: [Entry] = []
    
    init(_ viewModel: String) {
        self.viewModel = viewModel
        self.refresh();
        print(entries);
    }

    var body: some View {
        VStack {
            ForEach (entries) {entry in
                HStack {
                    Text(entry.key)
                    Text(entry.value)
                }
            }
        }.onAppear {
            self.refresh();
        }
    }
    
    func refresh() {
        let x = try! CNContactStore().unifiedContact(withIdentifier: self.viewModel, keysToFetch: keys)
        let attr = x.instantMessageAddresses;
        
        for i in attr {
            self.entries.append(Entry(i.value.service,i.value.username))
        }
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
