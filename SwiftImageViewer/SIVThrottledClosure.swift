//
//  SIVThrottledClosure.swift
//  SwiftImageViewer
//
//  Created by Alex on 24/8/2016.

import Foundation

public typealias SIVClosure = () -> ()
class SIVThrottledClosure {
    private let closure: SIVClosure
    private let interval: TimeInterval
    private var prev_source:DispatchSourceTimer?
    
    init (interval:TimeInterval, closure:@escaping SIVClosure){
        self.closure = closure
        self.interval = interval
    }
    
    // Throttled execution
    func schedule(){
        // Cancel previous run request
        if let prev_source = prev_source {
            prev_source.cancel()
        }
        
        let source = DispatchSource.makeTimerSource(queue: .main)
        source.scheduleOneshot(deadline: .now() + .milliseconds(Int(interval * 1000)))
        source.setEventHandler{[weak self] in
            self?.closure()
            source.cancel()
        }
        source.resume()
        prev_source = source
    }
}
