protocol P1: NSObjectProtocol, P2, P3 {
    func p1()
}

protocol P2: P4, ExtraOnes {
    func p2()
}

protocol P3 {
    func p3()
}

protocol P4 {
    func p4()
}
