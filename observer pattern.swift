import Swift
import UIKit

protocol EventType {
    typealias RegistrationType : Hashable
    typealias MessageType
    
    mutating func registerObserver(observer: RegistrationType, callback: MessageType -> ())
    mutating func removeObserver(observer: RegistrationType)
    
    func postNotifications(_ : MessageType)
    
    var registrar : [RegistrationType : MessageType -> ()] { get set }
}

extension EventType {
    mutating func registerObserver(observer: RegistrationType, callback: MessageType -> ()) {
        registrar[observer] = callback
    }
    
    mutating func removeObserver(observer: RegistrationType) {
        registrar.removeValueForKey(observer)
    }
    
    func postNotifications(m : MessageType) {
        for (_, callback) in self.registrar {
            callback(m)
        }
    }
}

// We discover that the ObserableType is really a special case of the EventType, where MessageType == Self
protocol ObservableType : EventType {
    typealias MessageType = Self
}

// We have one line left to Mad Lib for a fully functioning ObservableType:

struct Thing : ObservableType {
    var registrar : [ObjectIdentifier : Thing -> ()]
}

// Now we'll construct a EventType that signals something other than itself

protocol Employee {
    var name : String { get }
    
    var activity : String { get set }
}

struct Developer : Employee, EventType {
    var registrar : [ObjectIdentifier : (String, String) -> ()] = [:]

    let name : String
    var activity : String {
        didSet {
            postNotifications((self.name, self.activity))
        }
    }
    
    init(name: String, activity: String) {
        self.name = name
        self.activity = activity
    }
}

final class Manager {
    let name : String
    
    func micromanage(name: String, activity: String) {
        print("\(self.name) is checking in on \(name), who is \(activity).")
    }
    
    func micromanage(e: Employee) {
        print("\(self.name) is checking in on \(e.name), who is \(e.activity).")
    }
    
    init(name: String) {
        self.name = name
    }
}

let alice = Manager(name: "Alice")
var bob = Developer(name: "Bob", activity: "checking email")

bob.registerObserver(ObjectIdentifier(alice), callback: alice.micromanage)
bob.activity = "Nerfing around"

// Observed problem: all of our callbacks must accept the same signature of types. What we want looks like most delegate patterns in Objective-C:
//
//    @protocol UITableViewDelegate
//
//    - (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
//    - (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section;
//
//    @end
//
// The message pattern seems at odds with how we conventionally delegate. We need multiple actions on our targets. Swifts rigid type system again appears to interfere with the dynamic types we took for granted in Objective-C.
//
// But actually this is not a problem. We can formulate the delegate pattern as another special case of the message bus, wherein we pass ourselves for context, plus some parameters.
protocol DelegateType : EventType {
    typealias Parameters
    typealias MessageType = (Self, Parameters)
}

// We expose these Parameters as enumerations with associated values.

struct ViewModel : DelegateType {
    typealias Parameters = State
    
    enum State {
        case Valid(String)
        case Invalid(String)
        case Cancelled
    }
    
    var state : State {
        didSet {
            postNotifications((self, state))
        }
    }
    
    var registrar : [ObjectIdentifier : (ViewModel, State) -> ()]
}

// Consumers of the Parameters object dispatch against it.

final class Button {
    var backgroundColor : UIColor
    
    func viewModelChangedState(viewModel: ViewModel, state: ViewModel.State) {
        backgroundColor = {
            switch (state) {
            case .Valid(_): return UIColor.greenColor()
            case .Invalid(_): return UIColor.redColor()
            case .Cancelled: return UIColor.yellowColor()
            }
        }()
    }
    
    init(backgroundColor: UIColor) {
        self.backgroundColor = backgroundColor
    }
}

var viewModel  = ViewModel(state: .Valid("👍"), registrar: [:])
var button = Button(backgroundColor: UIColor.greenColor())
viewModel.registerObserver(ObjectIdentifier(button), callback: button.viewModelChangedState)
