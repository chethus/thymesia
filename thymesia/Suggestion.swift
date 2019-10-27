/*
README

Terms:
  entry: a key value pair
  contact: an array of entries representing a person
  contacts: an array of contact representing the entire contact book

func initialize_dist(contacts: [[Entry]]): takes contacts(book) and fill up the distribution table, used when the app boots up

func remove_contact(contact: [Entry]): takes a contact and remove it from the distribution table

func generate_suggestions(existing: [Entry]) -> Array<Entry>: takes an array of entries already in the current contact and returns a sorted array of recommeneded entries (from most likely to least likely)

func addVal(keyVal: Entry, existing: [Entry]): takes the new entry and an array of entried that's already there, used when the user adds a new entry while editing

func delVal(keyVal: Entry, existing: [Entry]): used when the user deletes a particular entry



*/

import Foundation
struct Entry : Hashable {
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
}

struct Pair : Hashable {
    static func == (lhs: Pair, rhs: Pair) -> Bool {
        return lhs.key == rhs.key && lhs.value == rhs.value
    }

    init(_ t: Entry, _ u: Entry) {
        key = t
        value = u
    }

    let key : Entry
    let value : Entry

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(value)
    }
}

var inter = [Pair: Int]()
var totals = [Entry: Int]()

/*
keyVal: the new kv pair to be added
existing; a list of kv pairs that has already been entered in this specific contact
*/
func addVal(keyVal: Entry, existing: [Entry]) {
  if totals[keyVal] == nil {
    totals[keyVal] = 0
  }
  totals[keyVal] = totals[keyVal]! + 1
  if !(existing.isEmpty) {
    for oldPair in existing {
      addInter(keyVal1: keyVal, keyVal2: oldPair)
    }
  }
}

/*
Should NOT be called by front-end
keyVal1: new key-value pair added
keyVal2: old
*/
func addInter(keyVal1: Entry, keyVal2: Entry) {
  let hashInter1 = Pair(keyVal1, keyVal2)
  let hashInter2 = Pair(keyVal2, keyVal1)
  if inter[hashInter1] == nil {
    inter[hashInter1] = 0
  }
  inter[hashInter1] = inter[hashInter1]! + 1
  if inter[hashInter2] == nil {
    inter[hashInter2] = 0
  }
  inter[hashInter2] = inter[hashInter2]! + 1
}

/*
keyVal: the kv pair to be deleted
existing; a list of kv pairs that has already been entered in this specific contact
*/
func delVal(keyVal: Entry, existing: [Entry]) {
  totals[keyVal] = totals[keyVal]! - 1
  if !(existing.isEmpty) {
    for oldPair in existing {
      if keyVal != oldPair {
        delInter(keyVal1: keyVal, keyVal2: oldPair)
      }
    }
  }
}

/*
Should NOT be called by front-end
keyVal1: key-value pair to be deleted
keyVal2: old
*/
func delInter(keyVal1: Entry, keyVal2: Entry) {
  let hashInter1 = Pair(keyVal1, keyVal2)
  let hashInter2 = Pair(keyVal2, keyVal1)
  inter[hashInter1] = inter[hashInter1]! - 1
  inter[hashInter2] = inter[hashInter2]! - 1
}

/*
P(kv1|kv2) = P(kv1, kv2)/P(kv2)
*/
func calc_prob(kv1: Entry, kv2: Entry) -> Double {
  let p_num = inter[Pair(kv1, kv2)]
  let p_denom = totals[kv2]
  if p_denom == 0 {
    return 0
  }
  return Double(p_num!) / Double(p_denom!)
}

func generate_suggestions(existing: [Entry]) -> Array<Entry> {
  var suggestions = [(Entry, prob: Double)]()
  for (kvpair, _) in totals {
    var bayesian_sum = 0.0
    for given in existing {
      if kvpair != given {
        bayesian_sum += calc_prob(kv1: kvpair, kv2: given)
      }
    }
    suggestions.append((kvpair, bayesian_sum))
  }
  suggestions.sort(by: { $0.prob > $1.prob })
  var ranked_suggestions = [Entry]()
  for (kv, _) in suggestions {
    ranked_suggestions.append(kv)
  }
  return ranked_suggestions
}

func initialize_dist(contacts: [[Entry]]) {
  for contact in contacts {
    var ext = [Entry]()
    for entry in contact {
      addVal(keyVal: entry, existing: ext)
      ext.append(entry)
    }
  }
}

func remove_contact(contact: [Entry]) {
  var ext = [Entry]()
  for entry in contact {
    ext.append(entry)
  }
  for entry in contact {
    delVal(keyVal: entry, existing: ext)
    if let index = ext.firstIndex(of: entry) {
      ext.remove(at: index)
    }
  }
}

func suggest_key(value: String, valLists: [String: [String]]) -> Entry {
  var guess = Entry("", value)
  var highest_count = -1
  for (entry, count) in totals {
    if (entry.value.range(of: value, options: .caseInsensitive) != nil) && (count > highest_count) {
      highest_count = count
      guess = entry
    }
  }
  if highest_count < 0 {
    var maxKey = ""
    var maxProp: Double = 0
    for (key, valList) in valLists {
      var valProp: Double = 0
      for val in valList {
        if val.range(of: value, options: .caseInsensitive) != nil {
          valProp += 1
        }
      }
      valProp /= Double(valList.count)
      if valProp > maxProp {
        maxKey = key
        maxProp = valProp
      }
    }
    guess = Entry(maxKey, value)
  }
  return guess
}
