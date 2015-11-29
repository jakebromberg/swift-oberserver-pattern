import Swift
import UIKit

protocol MessageBusType {
    typealias RegistrationType : Hashable
    typealias MessageType
    
    mutating func registerObserver(observer: RegistrationType, callback: MessageType -> ())
    mutating func removeObserver(observer: RegistrationType)
    
    func postNotifications(_ : MessageType)
    
    var registrar : [RegistrationType : MessageType -> ()] { get set }
}

extension MessageBusType {
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

// The ObserableType is a special case of MessageBusType, where MessageType == Self
protocol ObservableType : MessageBusType {
    mutating func registerObserver(observer: RegistrationType, callback: Self -> ())
    mutating func removeObserver(observer: RegistrationType)

    func postNotifications(_ : Self)

    var registrar : [RegistrationType : Self -> ()] { get set }
}

protocol Employee {
    var name : String { get }
    
    var activity : String { get set }
}

struct Developer : Employee, MessageBusType {
    let name : String
    var activity : String {
        didSet {
            postNotifications((self.name, self.activity))
        }
    }
    
    var registrar : [ObjectIdentifier : (String, String) -> ()]
}

final class Manager {
    let name : String
    
    func micromanage(name: String, activity: String) {
        print("\(self.name) is checking in on \(name), who is \(activity).")
    }
    
    init(name: String) {
        self.name = name
    }
}

let alice = Manager(name: "Alice")

var bob = Developer(name: "Bob", activity: "checking email", registrar: [:])
bob.registerObserver(ObjectIdentifier(alice), callback: alice.micromanage)

bob.activity = "working on Core Metrics"
bob.activity = "watching YouTube"
bob.activity = "eating lunch"
bob.activity = "Nerfing around"

struct ViewModel : MessageBusType {
    enum ViewModelState {
        case Valid(String)
        case Invalid(String)
        case Cancelled
    }
    
    var state : ViewModelState {
        didSet {
            postNotifications((self, state))
        }
    }
    
    var registrar : [ObjectIdentifier : (ViewModel, ViewModelState) -> ()]
}

final class Button {
    var backgroundColor : UIColor
    
    func widgetChangedState(w: ViewModel, s: ViewModel.ViewModelState) {
        func newBackgroundColor() -> UIColor {
            switch (s) {
            case .Valid(_): return UIColor.greenColor()
            case .Invalid(_): return UIColor.redColor()
            case .Cancelled: return UIColor.yellowColor()
            }
        }
        
        backgroundColor = newBackgroundColor()
    }
    
    init(backgroundColor: UIColor) {
        self.backgroundColor = backgroundColor
    }
}

var viewModel  = ViewModel(state: .Valid("👍"), registrar: [:])
var button = Button(backgroundColor: UIColor.greenColor())
viewModel.registerObserver(ObjectIdentifier(button), callback: button.widgetChangedState)