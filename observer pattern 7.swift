protocol RegistrationType {
    typealias ObserverType
    typealias SubjectType
    
    var observer : ObserverType { get set }
    var callback : SubjectType -> () { get }
}

extension RegistrationType where ObserverType : Equatable {
    func isEqualTo<T : RegistrationType>(other: T) -> Bool {
        if let o = other as? Self { return o.observer == self.observer }
        return false
    }
}

struct PointerRegistration<T> : RegistrationType {
    typealias ObserverType = AnyObject?
    
    weak var observer : AnyObject?
    let callback : T -> ()
    
    func isEqualTo<U : RegistrationType>(other: U) -> Bool {
        if let o = other as? PointerRegistration<T> { return o.observer === self.observer }
        return false
    }
}

func ==<T, U>(lhs: PointerRegistration<T>, rhs: PointerRegistration<U>) -> Bool {
    return lhs.isEqualTo(rhs)
}

struct ValueRegistration<Subject, Observer : Equatable> : RegistrationType {
    var observer : Observer
    let callback : Subject -> ()
    
    func isEqualTo<U : RegistrationType>(other: U) -> Bool {
        if let o = other as? ValueRegistration<Subject, Observer> { return o.observer == self.observer }
        return false
    }
}

func ==<T, U, V, W>(lhs: ValueRegistration<T, U>, rhs: ValueRegistration<V, W>) -> Bool {
    return lhs.isEqualTo(rhs)
}

protocol ObservableType {
    typealias ObserverType
    typealias Registration : RegistrationType
    
    var registrar : [Registration] { get set }
    
    mutating func registerObserver(observer: ObserverType, callback: Self -> ())
    mutating func removeObserver(observer: ObserverType)
    func postNotifications(subject: Self)
}

extension ObservableType where Registration == PointerRegistration<Self> {
    mutating func registerObserver(observer: AnyObject, callback: Self -> ()) {
        removeObserver(observer)
        registrar.append(Registration(observer: observer, callback: callback))
    }
    
    mutating func removeObserver(observer: AnyObject) {
        registrar = registrar.filter { e in
            return e.observer !== observer
        }
    }
    
    func postNotifications(subject: Self) {
        for r in registrar where r.observer != nil {
            r.callback(subject)
        }
    }
}

extension ObservableType where ObserverType : Equatable {
    typealias Registration = ValueRegistration<Self, ObserverType>
    
    mutating func registerObserver(observer: ObserverType, callback: Self -> ()) {
        removeObserver(observer)
        registrar.append(Registration(observer: observer, callback: callback))
    }
    
    mutating func removeObserver(observer: ObserverType) {
        registrar = registrar.filter { r in
            return r.observer != observer
        }
    }
    
    func postNotifications(subject: Self) {
        registrar.forEach { $0.callback(subject) }
    }
}

protocol Employee : ObservableType {
    var name : String { get }

    var currentActivity : String { get set }
}

struct Developer : Employee {
    let name : String
    var registrar : [PointerRegistration<Developer>]
    
    var currentActivity : String {
        didSet {
            postNotifications(self)
        }
    }
    
    init(name : String, registrar : [PointerRegistration<Developer>], currentActivity : String) {
        self.name = name
        self.registrar = registrar
        self.currentActivity = currentActivity
    }
}

struct Pivot<Observer : Equatable> : Employee {
    typealias ObserverType = Observer
    
    let name : String
    var registrar : [ValueRegistration<Pivot, Observer>]
    
    var currentActivity : String {
        didSet {
            postNotifications(self)
        }
    }
}

final class Manager : Equatable {
    let name : String
    
    func checkInOnEmployee<E : Employee>(e: E) {
        print("\(self.name) is checking in on \(e.name), who's \(e.currentActivity).")
    }

    init(name: String) {
        self.name = name
    }
}

func ==(lhs: Manager, rhs: Manager) -> Bool {
    return lhs.name == rhs.name
}

let alice = Manager(name: "Alice")

var bob = Developer(name: "Bob", registrar: [], currentActivity: "checking email")
bob.registerObserver(alice, callback: alice.checkInOnEmployee)

bob.currentActivity = "working on Core Metrics"
bob.currentActivity = "watching YouTube"
bob.currentActivity = "eating lunch"

var caroline = Pivot<Manager>(name: "Caroline", registrar: [], currentActivity: "refactoring tickets")
caroline.registerObserver(alice) { e in
    print("\(e.name) is \(e.currentActivity).")
}

bob.currentActivity = "Nerfing around"

caroline.currentActivity = "billing hours"
