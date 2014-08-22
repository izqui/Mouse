//From:

import Foundation

func go(routine: () -> ()) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), routine)
}

func go(routine: @autoclosure() -> ()) {
    go(routine as () -> ())
}

infix operator  <- { associativity left }
func <- (c: Chan, value: AnyObject?) { c.send(value) }
func <- (inout value: AnyObject?, chan: Chan) { value = chan.recv() }

prefix operator <- {}
prefix func <- (inout chan: Chan) -> AnyObject? { return chan.recv() }

class Chan {
    class Waiter : NSObject {
        enum Direction : Int {
            case Receive = 0
            case Send
        }

        let direction : Direction
        var fulfilled : Bool = false
        let sema : dispatch_semaphore_t = dispatch_semaphore_create(0)

        var value : AnyObject? {
        get {
            if direction == .Receive {
                fulfilled = true
                dispatch_semaphore_signal(sema)
            } else if !fulfilled {
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)
            }
            return _value
        }
        set(newValue) {
            _value = newValue
            if direction == .Send {
                fulfilled = true
                dispatch_semaphore_signal(sema)
            } else if !fulfilled {
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)
            }
        }
        }
        var _value : AnyObject?

        init(direction : Direction) {
            self.direction = .Send
        }
    }

    var lock : NSLock = NSLock()

    let capacity : Int = Int.max
    var buffer : [AnyObject?] = []
    var sendQ : [Waiter] = []
    var recvQ : [Waiter] = []

    init (buffer:Int) {
        self.capacity = buffer
    }

    var count : Int {
        return buffer.count
    }

    func send(value: AnyObject?) {
        lock.lock()

        // see if we can immediately pair with a waiting receiver
        if let recvW = removeWaiter(&recvQ) {
            recvW.value = value
            lock.unlock()
            return
        }

        // if not, use the buffer if there's space
        if self.buffer.count < self.capacity {
            self.buffer.append(value)
            lock.unlock()
            return
        }

        // otherwise block until we can send
        let sendW = Waiter(direction: .Send)
        sendQ.append(sendW)
        lock.unlock()
        sendW.value = value
    }

    func recv() -> AnyObject? {
        lock.lock()

        // see if there's oustanding messages in the buffer
        if buffer.count > 0 {
            let value : AnyObject? = buffer.removeAtIndex(0)

            // unblock waiting senders using buffer
            if let sendW = removeWaiter(&sendQ) {
                buffer.append(sendW.value)
            }

            lock.unlock()
            return value
        }

        // if not, pair with any waiting senders
        if let sendW = removeWaiter(&sendQ) {
            lock.unlock()
            return sendW.value
        }

        // otherwise, block until a message is available
        let recvW = Waiter(direction: .Receive)
        recvQ.append(recvW)
        lock.unlock()

        return recvW.value
    }

    func removeWaiter(inout waitQ : Array<Waiter>) -> Waiter? {
        if waitQ.count > 0 {
            return waitQ.removeAtIndex(0)
        }
        return nil
    }
}
