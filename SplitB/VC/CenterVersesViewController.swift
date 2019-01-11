//
//  CenterVersesViewController.swift
//  SplitB
//
//  Created by Denis Dobanda on 22.11.18.
//  Copyright © 2018 Denis Dobanda. All rights reserved.
//

import UIKit

class CenterVersesViewController: CenterViewController {

    var verseTextManager: VerseTextManager?
    var verseManager: VerseManager?
    var verseTextView: VerseTextView! { didSet{ verseTextView?.delegate = self }}
    
    override var customTextView: CustomTextView! {
        get {return verseTextView}
        set {print ( "Error: set customTextView")}
    }
    override var coreManager: Manager? {
        get {
            return verseManager
        }
        set {
            print("Error!! didSet coreManager")
        }
    }
    override var textManager: TextManager? {
        get {
            return verseTextManager
        }
        set {
            print("Error!! didSet textManager")
        }
    }
    
    @IBOutlet weak var search: SearchTextField!
    private var isInSearch = false {
        didSet {
            topScrollConstraint.constant = isInSearch ? search.frame.height : 0.0
            if isInSearch {
                search.isHidden = false
                search.text = nil
                search.becomeFirstResponder()
            } else {
                search.isHidden = true
                search.text = nil
                view.endEditing(true)
            }
        }
    }
    @IBOutlet weak var topScrollConstraint: NSLayoutConstraint!
    
    @IBAction func searchAction(_ sender: UIBarButtonItem) {
        isInSearch = !isInSearch
    }
    
    private var tapInProgress = false
    private var panInProgress = false
    private var menuRect: CGRect?
    private var firstMenuRect: CGRect?
    private var timerScrollingMenu: Timer?
    
    @IBAction func searchDidEnd(_ sender: SearchTextField) {
        if let text = sender.text {
            parseSearch(text: text)
        }
        isInSearch = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let titles = verseManager?.getBooksTitles() {
            search.filterStrings(titles)
        }
        search.theme.font = UIFont.systemFont(ofSize: 12)
        search.theme.bgColor = UIColor (red: 0.9, green: 0.9, blue: 0.9, alpha: 0.9)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(touch(sender: )))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func loadTextManager(_ forced: Bool = true) {
//        var first: [String] = []
//        var second: [String] = []
//        let texts = verseTextManager?.getTwoStrings()
//        if let f = texts?.0 {
//            first = f
//        }
//        if let s = texts?.1 {
//            second = s
//        }
        if forced, let verses = verseManager?.getVerses() {
            verseTextManager = VerseTextManager(verses: verses)
            if let m = coreManager {
                navigationItem.title = "\(m.get1BookName()) \(m.chapterNumber)"
            }
            
            switch verseTextView {
            case .some:
                verseTextView.removeFromSuperview()
            default:break
            }
            
            verseTextView = VerseTextView(frame: scrollView.bounds)
            verseTextView.verseTextManager = verseTextManager
            scrollView.addSubview(verseTextView)
            scrollView.scrollRectToVisible(CGRect(0, 0, 1, 1), animated:false)
        }
        textManager?.fontSize = fontSize
        customTextView.setNeedsLayout()
    }
    
    @objc private func touch(sender: UITapGestureRecognizer) {
        if sender.state == .ended && !panInProgress {
            if !overlapped, let rect = verseTextView.selectVerse(at: sender.location(in: scrollView)) {
                tapInProgress = true
                
                switch firstMenuRect {
                case .none:
                    menuRect = rect
                    firstMenuRect = rect
                case .some(let r):
                    menuRect = CGRect(bounding: r, with: rect)
                    menuRect!.size.width = scrollView.bounds.width
                }
                showMenu()
            }
        }
        delegate?.collapseSidePanels?()
        overlapped = false
        panInProgress = false
    }
    
    private func showMenu() {
        if let s = customTextView.getSelection(), let rect = menuRect {
            textToCopy = s
            becomeFirstResponder()
            let copyItem = UIMenuItem(title: "Copy".localized, action: #selector(copySelector))
            let defineItem = UIMenuItem(title: "Define".localized, action: #selector(defineSelector))
            UIMenuController.shared.menuItems = [copyItem, defineItem]
            UIMenuController.shared.setTargetRect(rect, in: scrollView)
            UIMenuController.shared.setMenuVisible(true, animated: true)
        } else {
            tapInProgress = false
            panInProgress = false
            menuRect = nil
            firstMenuRect = nil
        }
    }
    
    private func parseSearch(text: String) {
        guard text.count > 0,
            let matched = text.capturedGroups(withRegex: String.regexForBookRefference)
            else {return}
        /*
        var indexOfChapterStart = 0
        while (!("0"..."9" ~= text[indexOfChapterStart]) ||
            indexOfChapterStart == 0) &&
            indexOfChapterStart < text.count - 1 {
            indexOfChapterStart += 1
        }
        var indexOfChapterEnd = indexOfChapterStart
        while "0"..."9" ~= text[indexOfChapterEnd] &&
            indexOfChapterEnd < text.count - 1 {
            indexOfChapterEnd += 1
        }
        var indexOfVerseStart = indexOfChapterEnd
        while !("0"..."9" ~= text[indexOfVerseStart]) &&
            indexOfVerseStart < text.count - 1 {
            indexOfVerseStart += 1
        }
        var indexOfVerseEnd = indexOfVerseStart
        while "0"..."9" ~= text[indexOfVerseEnd] &&
            indexOfVerseEnd < text.count - 1 {
            indexOfVerseEnd += 1
        }
        if "0"..."9" ~= text[indexOfChapterStart],
            indexOfChapterEnd == text.count - 1 {
            indexOfChapterEnd += 1
        }
        if indexOfVerseStart != indexOfChapterEnd,
            indexOfVerseEnd == text.count - 1 {
            indexOfVerseEnd += 1
        }
        let book = String(text[..<text.index(indexOfChapterStart)]).trimmingCharacters(in: .whitespacesAndNewlines)
        let chapter = String(text[indexOfChapterStart..<indexOfChapterEnd])
        let verse = String(text[indexOfVerseStart..<indexOfVerseEnd])
//        print(s1)
//        print("--")
//        print(s2, Int(s2))
        */
        let book = matched[0]
        verseManager?.setBook(byTitle: book)
        
        if matched.count > 1, let number = Int(matched[1]) {
            verseManager?.setChapter(number: number)
        }
        loadTextManager()
        if matched.count > 2 {
            verseTextView.executeRightAfterDrawingOnce = {
                if let v = Int(matched[2]), let rect = self.verseTextView.getRectOf(v) {
                    var r = rect
                    r.size.height = self.scrollView.bounds.height
                    let o = self.scrollView.convert(r.origin, from: self.verseTextView)
                    self.scrollView.setContentOffset(o, animated: true)
                    if matched.count > 3,
                        let last = matched.last,
                        let lastVerse = Int(last) {
                        self.verseTextView.highlight(v, throught: lastVerse)
                    }else {
                        self.verseTextView.highlight(v)
                    }
                }
            }
        }
    }
    
//    private func highlight(_ rect: CGRect) {
//        var r = rect
//        r.size.width = scrollView.bounds.width
//        let newView = UIView(frame: r)
//        newView.backgroundColor = UIColor.yellow.withAlphaComponent(0.4)
//        scrollView.addSubview(newView)
//        UIView.animate(withDuration: 1.0, delay: 1, animations: {
//            newView.layer.opacity = 0
//        }) { (_) in
//            newView.removeFromSuperview()
//        }
//
//    }

    override func UIMenuControllerWillHide() {
        if !tapInProgress {
            verseTextView.clearSelection()
        }
    }
    
    override func longTap(sender: UILongPressGestureRecognizer) {
        super.longTap(sender: sender)
        panInProgress = true
        tapInProgress = false
        menuRect = nil
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        timerScrollingMenu?.invalidate()
        timerScrollingMenu = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] (t) in
            self?.showMenu()
            self?.timerScrollingMenu = nil
            t.invalidate()
        }
    }
}
