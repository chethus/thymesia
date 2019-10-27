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

// Main view
struct ContentView: View {
    
    @State var contacts: [Entry] = []; // (Identifier, Name)
    
    @State var edits: [Entry] = []
    @State var tag: Entry = emptyEntry;
    @State var searchText: String = "";
    @State var currentPage = 0
    
    func delete(at offsets: IndexSet) {
        for i in offsets {
            let x = (try! CNContactStore().unifiedContact(withIdentifier: contacts[i].key, keysToFetch: keys).mutableCopy() as! CNMutableContact)
            let save = CNSaveRequest()
            save.delete(x);
            try! CNContactStore().execute(save);
    
            contacts.remove(at: i)
        }
    }
    
    var body: some View {
        TabView (selection: $tag) {
            NavigationView {
                VStack {
                    SearchBar(text: $searchText)
                    ScrollView (.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(rankVals(allEntries(contacts))) { entry in
                            Button(entry.value) {
                                self.searchText.append(" \(entry.description)")
                            }.padding(4).background(self.chooseColor(entry.value)).cornerRadius(CGFloat(10)).foregroundColor(.white)
                        }
                        Spacer();
                    }
                    }.frame(height: 35).padding(Edge.Set.horizontal, nil)
                    Divider()
                    List {
                        ForEach(search(searchText, allEntries(contacts), contacts), id: \.self) {contact in
                            NavigationLink(destination: ContactField(contact.key).navigationBarTitle(Text(contact.value), displayMode:.inline).navigationBarItems(trailing: Button("Edit"){
                                if !self.edits.contains(contact) {
                                    self.edits.append(contact)
                                }
                                self.tag = contact;
                                })) {
                                Text(contact.value)
                            }
                        }.onDelete(perform: delete)
                    }
                }.navigationBarItems(trailing:
                    Button(action: {
                        let c = CNMutableContact();
                        let save = CNSaveRequest();
                        save.add(c, toContainerWithIdentifier: nil)
                        try! CNContactStore().execute(save)
                        
                        let str = CNContactFormatter.string(from: c, style: .fullName) ?? "No Name";
                        let entry = Entry(c.identifier,str);
                        self.edits.append(entry)
                        self.contacts.insert(entry, at: 0)
                        self.tag = entry;
                    }) {
                        Image(systemName: "plus").imageScale(.large).padding()
                }).navigationBarTitle(Text("Search"))
            }.tabItem{
                Image(systemName: "magnifyingglass")
            }.tag(emptyEntry)
            ForEach(edits, id: \.self) { edit in
                NavigationView {
                    ContactField(edit.key).navigationBarTitle(Text(edit.value),displayMode: .inline).navigationBarItems(leading:
                    Button(action: {
                        self.tag = emptyEntry
                        self.edits.removeAll{$0 == edit}
                    }) {
                        Image(systemName: "checkmark").imageScale(.large).padding()
                        },trailing:
                        Button(action: {
                            let c = CNMutableContact();
                            let save = CNSaveRequest();
                            save.add(c, toContainerWithIdentifier: nil)
                            try! CNContactStore().execute(save)
                            
                            let str = CNContactFormatter.string(from: c, style: .fullName) ?? "No Name";
                            let entry = Entry(c.identifier,str);
                            self.edits.append(entry)
                            self.contacts.insert(entry, at: 0)
                            self.tag = entry;
                        }) {
                            Image(systemName: "plus").imageScale(.large).padding()
                        })
                }.tabItem {
                    Image(systemName: "circle.fill").imageScale(.small)
                }.tag(edit)
            }
        }.onAppear {
            self.refreshContacts()
        }
    }
    
    func chooseColor(_ str: String) -> Color {
        return Color(white: Double(str.hashValue % 7)/Double(9))
    }
    
    func refreshContacts() {
        contacts = []
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        try! CNContactStore().enumerateContacts(with: request) {
            (contact, stop) in
            let str = CNContactFormatter.string(from: contact, style: .fullName) ?? "No Name";
            self.contacts.insert(Entry(contact.identifier, str), at: 0)
        }
        initializeDist(contacts: allEntries(contacts))
    }
    
    func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func entries(_ identifier: String) -> [Entry] {
        var result: [Entry] = [];
        
        let x = try! CNContactStore().unifiedContact(withIdentifier: identifier, keysToFetch: keys)
        let attr = x.instantMessageAddresses;
        
        for i in attr {
            result.append(Entry(i.value.service,i.value.username))
        }
        
        return result;
    }
    
    func allEntries(_ contacts: [Entry]) -> [[Entry]]{
        var result: [[Entry]] = []
        for c in contacts {
            result.append(entries(c.key))
        }
        return result
    }
    
    func search(_ str:String, _ contacts:[[Entry]], _ identifiers: [Entry]) -> [Entry]{
      let tokens = str.replacingOccurrences(of: "![A-Za-z0-9 :]", with: "", options: [.regularExpression]).split(separator: " ")
      var results:[Entry] = []
        for i in 0..<contacts.count {
        var all = true
        for token in tokens {
          var cur = false
          for entry in contacts[i] {
            if entry.description.range(of: token, options: .caseInsensitive) != nil {
              cur = true
              break
            }
          }
          if !cur {
            all = false
            break
          }
        }
        if all {
          results.append(identifiers[i])
        }
      }
      return results
    }
}

struct ContactField : View {
    let viewModel: String
    let total = 50
    @State private var entries: [Entry] = Array<Entry>(repeating: emptyEntry, count: 50)
    @State private var len = 0;
    
    init(_ viewModel: String) {
        self.viewModel = viewModel;
    }
    
    func chooseColor(_ str: String) -> Color {
        return Color(white: Double(str.hashValue % 7)/Double(9))
    }

    var body: some View {
        VStack {
            ScrollView (.horizontal, showsIndicators: false) {
            HStack {
                ForEach(generateSuggestions(existing: entries)) { entry in
                    Button(entry.value) {
                        self.entries[self.len] = entry
                        self.len += 1
                        self.update();
                    }.padding(4).background(self.chooseColor(entry.value)).cornerRadius(CGFloat(10)).foregroundColor(.white)
                }
                Spacer()
            }
            }.frame(height: 35)
            Divider();
            ForEach (entries.indices) {index in
                if (index < self.len) {
                    HStack {
                        TextField("", text: self.$entries[index].key, onCommit: {
                            if (self.entries[index].value.isEmpty) {
                                for i in index..<(self.total-1) {
                                    self.entries[i] = self.entries[i+1]
                                }
                                self.len -= 1
                                self.update();
                                return;
                            }
                            self.update();
                        }).frame(width: CGFloat(100.0), height: nil, alignment: .leading).foregroundColor(.gray)
                        TextField("", text: self.$entries[index].value, onCommit: {
                            if (self.entries[index].value.isEmpty) {
                                for i in index..<(self.total-1) {
                                    self.entries[i] = self.entries[i+1]
                                }
                                self.len -= 1
                                self.update();
                                return;
                            }
                            self.entries[index].key = suggest_key(value: self.entries[index].value)
                            self.update();
                        })
                    }
                    Divider();
                }
            }
            HStack {
                TextField("", text: self.$entries[self.len].key, onCommit: {
                    if (self.entries[self.len].value.isEmpty) {
                        return;
                    }
                    self.len += 1
                    self.update();
                }).frame(width: CGFloat(100.0), height: nil, alignment: .leading).foregroundColor(.gray)
                TextField("", text: self.$entries[self.len].value, onCommit: {
                    if (self.entries[self.len].value.isEmpty) {
                        return;
                    }
                    self.entries[self.len].key = suggest_key(value: self.entries[self.len].value)
                    self.len += 1
                    self.update();
                })
            }
            Divider();
            Spacer();
        }.padding().onAppear() {self.refresh()}
    }
    
    func refresh() {
        let x = try! CNContactStore().unifiedContact(withIdentifier: self.viewModel, keysToFetch: keys)
        let attr = x.instantMessageAddresses;
        
        for i in 0..<attr.count {
            self.entries[i] = Entry(attr[i].value.service, attr[i].value.username)
        }
        self.len = attr.count
    }
    
    func update() {
        let x = (try! CNContactStore().unifiedContact(withIdentifier: self.viewModel, keysToFetch: keys).mutableCopy() as! CNMutableContact)
        x.instantMessageAddresses = []
        
        for i in 0..<len {
            x.instantMessageAddresses.append(CNLabeledValue<CNInstantMessageAddress>(label: self.entries[i].key, value: CNInstantMessageAddress(username: self.entries[i].value, service: self.entries[i].key)))
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
