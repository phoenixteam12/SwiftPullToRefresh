//
//  ScrollViewExtension.swift
//  SwiftPullToRefresh
//
//  Created by Leo Zhou on 2017/12/19.
//  Copyright © 2017年 Wiredcraft. All rights reserved.
//

import UIKit

private var headerKey: UInt8 = 0
private var footerKey: UInt8 = 0
private var tempFooterKey: UInt8 = 0
private var tempHeaderKey: UInt8 = 0
private var refreshContextKey: UInt8 = 0

class ScrollViewRefreshContext {
    var offsetToken: NSKeyValueObservation?
    var stateToken: NSKeyValueObservation?
    
    func observeScrollView(scrollView: UIScrollView) {
        if offsetToken == nil {
            offsetToken = scrollView.observe(\.contentOffset) { [weak self] scrollView, _ in
                scrollView.spr_header?.scrollViewDidScroll(scrollView) // 先通知下拉刷新
                scrollView.spr_footer?.scrollViewDidScroll(scrollView) // 再上拉刷新
            }
        }
        
        if stateToken == nil {
            stateToken = scrollView.observe(\.panGestureRecognizer.state) { [weak self] scrollView, _ in
                guard scrollView.panGestureRecognizer.state == .ended else { return }
                
                scrollView.spr_header?.scrollViewDidEndDragging(scrollView)
                scrollView.spr_footer?.scrollViewDidEndDragging(scrollView)
            }
        }
    }
}

extension UIScrollView {
    
    private func getRefreshContext() -> ScrollViewRefreshContext {
        if let context = objc_getAssociatedObject(self, &refreshContextKey) as? ScrollViewRefreshContext {
            // 已经存在
            return context
        }
        // 没有存在，新建
        let context = ScrollViewRefreshContext()
        objc_setAssociatedObject(self, &refreshContextKey, context, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return context
    }

    public var spr_header: RefreshView? {
        get {
            return objc_getAssociatedObject(self, &headerKey) as? RefreshView
        }
        set {
            spr_header?.removeFromSuperview()
            objc_setAssociatedObject(self, &headerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            newValue.map { insertSubview($0, at: 0) }
            getRefreshContext().observeScrollView(scrollView: self)
        }
    }

    public var spr_footer: RefreshView? {
        get {
            return objc_getAssociatedObject(self, &footerKey) as? RefreshView
        }
        set {
            spr_footer?.removeFromSuperview()
            objc_setAssociatedObject(self, &footerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            newValue.map { insertSubview($0, at: 0) }
            getRefreshContext().observeScrollView(scrollView: self)
        }
    }

    private var spr_tempFooter: RefreshView? {
        get {
            return objc_getAssociatedObject(self, &tempFooterKey) as? RefreshView
        }
        set {
            objc_setAssociatedObject(self, &tempFooterKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var spr_tempHeader: RefreshView? {
        get {
            return objc_getAssociatedObject(self, &tempHeaderKey) as? RefreshView
        }
        set {
            objc_setAssociatedObject(self, &tempHeaderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Indicator header
    ///
    /// - Parameters:
    ///   - height: refresh view height and also the trigger requirement, default is 60
    ///   - action: refresh action
    public func spr_setIndicatorHeader(height: CGFloat = 60,
                                       action: @escaping () -> Void) {
        spr_header = IndicatorView(isHeader: true, height: height, action: action)
    }

    /// Indicator + Text header
    ///
    /// - Parameters:
    ///   - refreshText: text display for different states
    ///   - height: refresh view height and also the trigger requirement, default is 60
    ///   - action: refresh action
    public func spr_setTextHeader(refreshText: RefreshText = headerText,
                                  height: CGFloat = 60,
                                  action: @escaping () -> Void) {
        spr_header = TextView(isHeader: true, refreshText: refreshText, height: height, action: action)
    }

    /// GIF header
    ///
    /// - Parameters:
    ///   - data: data for the GIF file
    ///   - isBig: whether the GIF is displayed with full screen width
    ///   - height: refresh view height and also the trigger requirement
    ///   - action: refresh action
    public func spr_setGIFHeader(data: Data,
                                 isBig: Bool = false,
                                 height: CGFloat = 60,
                                 action: @escaping () -> Void) {
        spr_header = GIFHeader(data: data, isBig: isBig, height: height, action: action)
    }
    
    public func spr_setGIFHeader(images: [UIImage],
                                 isBig: Bool = false,
                                 height: CGFloat = 60,
                                 action: @escaping () -> Void) {
        spr_header = GIFHeader(images: images, isBig: isBig, height: height, action: action)
    }

    /// GIF + Text header
    ///
    /// - Parameters:
    ///   - data: data for the GIF file
    ///   - refreshText: text display for different states
    ///   - height: refresh view height and also the trigger requirement, default is 60
    ///   - action: refresh action
    public func spr_setGIFTextHeader(data: Data,
                                     refreshText: RefreshText = headerText,
                                     height: CGFloat = 60,
                                     action: @escaping () -> Void) {
        spr_header = GIFTextHeader(data: data, refreshText: refreshText, height: height, action: action)
    }

    /// Custom header
    /// Inherit from RefreshView
    /// Update the presentation in 'didUpdateState(_:)' and 'didUpdateProgress(_:)' methods
    ///
    /// - Parameter header: your custom header inherited from RefreshView
    public func spr_setCustomHeader(_ header: RefreshView) {
        self.spr_header = header
    }

    /// Custom footer
    /// Inherit from RefreshView
    /// Update the presentation in 'didUpdateState(_:)' and 'didUpdateProgress(_:)' methods
    ///
    /// - Parameter footer: your custom footer inherited from RefreshView
    public func spr_setCustomFooter(_ footer: RefreshView) {
        self.spr_footer = footer
    }

    /// Begin refreshing with header
    public func spr_beginHeaderRefreshing() {
        spr_header?.beginRefreshing()
    }
    
    public func spr_beginFooterRefreshing() {
        spr_footer?.beginRefreshing()
    }
    
    public func spr_endHeaderRefreshing() {
        spr_header?.endRefreshing()
    }
    
    public func spr_endFooterRefreshing() {
        spr_footer?.endRefreshing()
    }

    /// End refreshing with both header and footer
//    public func spr_endRefreshing() {
//        spr_header?.endRefreshing()
//        spr_footer?.endRefreshing()
//    }

    /// End refreshing with footer and remove it
//    public func spr_endRefreshingWithNoMoreData() {
//        spr_footer?.endRefreshing { [weak self] in
//            self?.spr_disableFooter()
//        }
//    }
    
    // 不能下拉刷新
    public func spr_disableHeader() {
        if spr_header != nil {
            spr_tempHeader = spr_header
        }
        self.spr_header = nil
    }

    public func spr_enableHeader() {
        if spr_header == nil {
            spr_header = spr_tempHeader
        }
    }
    
    // 不能加载更多
    public func spr_disableFooter() {
        if spr_footer != nil {
            spr_tempFooter = spr_footer
        }
        spr_footer?.endRefreshing { [weak self] in
            self?.spr_footer = nil
        }
    }

    /// Reset footer which is set to no more data
    public func spr_enableFooter() {
        if spr_footer == nil {
            spr_footer = spr_tempFooter
        }
    }

    /// Indicator footer
    ///
    /// - Parameters:
    ///   - height: refresh view height and also the trigger requirement, default is 60
    ///   - action: refresh action
    public func spr_setIndicatorFooter(height: CGFloat = 60,
                                       action: @escaping () -> Void) {
        spr_footer = IndicatorView(isHeader: false, height: height, action: action)
    }

    /// Indicator + Text footer
    ///
    /// - Parameters:
    ///   - refreshText: text display for different states
    ///   - height: refresh view height and also the trigger requirement, default is 60
    ///   - action: refresh action
    public func spr_setTextFooter(refreshText: RefreshText = footerText,
                                  height: CGFloat = 60,
                                  action: @escaping () -> Void) {
        spr_footer = TextView(isHeader: false, refreshText: refreshText, height: height, action: action)
    }

    /// Indicator auto refresh footer (auto triggered when scroll down to the bottom of the content)
    ///
    /// - Parameters:
    ///   - height: refresh view height, default is 60
    ///   - action: refresh action
    public func spr_setIndicatorAutoFooter(height: CGFloat = 60,
                                           action: @escaping () -> Void) {
        spr_footer = IndicatorAutoFooter(height: height, action: action)
    }

    /// Indicator + Text auto refresh footer (auto triggered when scroll down to the bottom of the content)
    ///
    /// - Parameters:
    ///   - loadingText: text display for refreshing
    ///   - height: refresh view height, default is 60
    ///   - action: refresh action
    public func spr_setTextAutoFooter(loadingText: String = loadingText,
                                      height: CGFloat = 60,
                                      action: @escaping () -> Void) {
        spr_footer = TextAutoFooter(loadingText: loadingText, height: height, action: action)
    }


    /// Clear the header
    public func spr_clearHeader() {
        spr_header = nil
    }

    /// Clear the footer
    public func spr_clearFooter() {
        spr_footer = nil
    }

}

/// Text display for different states
public struct RefreshText {
    let loadingText: String
    let pullingText: String
    let releaseText: String

    /// Initialization method
    ///
    /// - Parameters:
    ///   - loadingText: text display for refreshing
    ///   - pullingText: text display for dragging when don't reach the trigger
    ///   - releaseText: text display for dragging when reach the trigger
    public init(loadingText: String, pullingText: String, releaseText: String) {
        self.loadingText = loadingText
        self.pullingText = pullingText
        self.releaseText = releaseText
    }
}

public let loadingText = "Loading..."

public let headerText = RefreshText(
    loadingText: loadingText,
    pullingText: "Pull down to refresh",
    releaseText: "Release to refresh"
)

public let footerText = RefreshText(
    loadingText: loadingText,
    pullingText: "Pull up to load more",
    releaseText: "Release to load more"
)
