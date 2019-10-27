
import Foundation

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

/*
Takes a search string and a list of contacts.
Returns all contacts with the search string as a substring (case insensitive, white space insensitive, alphanumeric only)).
Example call:
print(search("hair:brown", [[Entry("School", "Berkeley"), Entry("Name", "Chase Norman"), Entry("Hair", "Brown")], [Entry("Name", "Andrew Bogdan"),Entry("School", "Berkeley"),Entry("Hair", "Brown")],[Entry("Name", "Chethan Bhateja"), Entry("School", "Berkeley"),Entry("Hair", "Black")],[Entry("Name", "David Shen"), Entry("School", "Berkeley"), Entry("Hair", "Black")]]))
*/
func search(_ str:String, _ contacts:[[Entry]]) -> [[Entry]]{
  let tokens = str.replacingOccurrences(of: "![A-Za-z0-9 :]", with: "", options: [.regularExpression]).split(separator: " ")
  var results:[[Entry]] = []
  for contact in contacts {
    var all = true
    for token in tokens {
      var cur = false
      for entry in contact {
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
      results.append(contact)
    }
  }
  return results
}

/*
Ranks different entries based on how evenly they split the search space.
Takes a list of the current contacts displayed in the search results.
Does not need a list of entries passed in because only entries present within the contacts list are relevant.
Example call:
rankVals([[Entry("School", "Berkeley"), Entry("Name", "Chase Norman"), Entry("Hair", "Brown")], [Entry("Name", "Andrew Bogdan"),Entry("School", "Berkeley"),Entry("Hair", "Brown")],[Entry("Name", "Chethan Bhateja"), Entry("School", "Berkeley"),Entry("Hair", "Black")],[Entry("Name", "David Shen"), Entry("School", "Berkeley"), Entry("Hair", "Black")]])
*/
func rankVals(_ contacts: [[Entry]]) -> [Entry] {
  var counts = [Entry: Double]()
  for contact in contacts {
    for entry in contact {
      counts[entry] = counts[entry] == nil ? 1 : counts[entry]! + 1
    }
  }
  let numCont = Double(contacts.count)
  let sortedCounts = counts.sorted{keyFunc(x: $0.1/numCont, y: $1.1/numCont)}
  var topEntries = [Entry]()
  for (entry, _) in sortedCounts {
    topEntries.append(entry)
  }
  return topEntries
}
func keyFunc(x: Double, y: Double) -> Bool{
  return (x - y)*(x + y - 1) < 0
}
