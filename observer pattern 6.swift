import Swift

protocol RegistrationType : Equatable {
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

struct ObserverRegistration<T> : RegistrationType {
    typealias ObserverType = AnyObject?
    typealias SubjectType = T
    
    weak var observer : AnyObject?
    let callback : T -> ()
    
    func isEqualTo<U : RegistrationType>(other: U) -> Bool {
        if let o = other as? ObserverRegistration<T> { return o.observer === self.observer }
        return false
    }
}

func ==<T, U>(lhs: ObserverRegistration<T>, rhs: ObserverRegistration<U>) -> Bool {
    return lhs.isEqualTo(rhs)
}


struct Registration<Observable, Observer : Equatable> : RegistrationType {
    typealias ObserverType = Observer
    typealias SubjectType = Observable
    
    var observer : Observer
    let callback : Observable -> ()
    
    func isEqualTo<U : RegistrationType>(other: U) -> Bool {
        if let o = other as? Registration<Observable, Observer> { return o.observer == self.observer }
        return false
    }
}

func ==<T, U, V, W>(lhs: Registration<T, U>, rhs: Registration<V, W>) -> Bool {
    return lhs.isEqualTo(rhs)
}

protocol ObservableType {
    typealias ObserverType
    typealias ObserverRegistrationType
    
    var registrar : [ObserverRegistrationType] { get set }
    
    mutating func registerObserver(observer: ObserverType, callback: Self -> ())
    mutating func removeObserver(observer: ObserverType)
    func postNotifications(subject: Self)
}

extension ObservableType where ObserverRegistrationType == ObserverRegistration<Self> {
    mutating func registerObserver(observer: AnyObject, callback: Self -> ()) {
        removeObserver(observer)
        let e = ObserverRegistration(observer: observer, callback: callback)
        registrar.append(e)
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

extension ObservableType where ObserverType : Equatable, ObserverRegistrationType == Registration<Self, ObserverType> {
    mutating func registerObserver(observer: ObserverType, callback: Self -> ()) {
        removeObserver(observer)
        registrar.append(Registration(observer: observer, callback: callback))
    }
    
    mutating func removeObserver(observer: ObserverType) {
        registrar = registrar.filter { r in
            return r.observer == observer
        }
    }
    
    func postNotifications(subject: Self) {
        registrar.forEach { r in r.callback(subject) }
    }
}

protocol Employee : ObservableType {
    var name : String { get }

    var currentActivity : String { get set }
}

class Developer : Employee {
    let name : String
    var registrar : [ObserverRegistration<Developer>]
    
    var currentActivity : String {
        didSet {
            postNotifications(self)
        }
    }
    
    init(name : String, registrar : [ObserverRegistration<Developer>], currentActivity : String) {
        self.name = name
        self.registrar = registrar
        self.currentActivity = currentActivity
    }
}

struct Pivot<Observer : Equatable> : Employee {
    typealias ObserverType = Observer
    typealias ObserverRegistrationType = Registration<Pivot, ObserverType>
    
    let name : String
    var registrar : [ObserverRegistrationType]
    
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

var bob = Developer(name: "Bob", registrar: [], currentActivity: "checking email")

let alice = Manager(name: "Alice")

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
