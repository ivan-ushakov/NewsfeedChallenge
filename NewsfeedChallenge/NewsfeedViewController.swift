//
//  NewsfeedViewController.swift
//  NewsfeedChallenge
//
//  Created by  Ivan Ushakov on 09/11/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import UIKit

struct TextArea {
    var width: CGFloat
    var height: CGFloat
    var lineHeight: CGFloat
}

typealias TextAreaBlock = (String, CGFloat) -> TextArea

enum TextAreaState {
    case full, short
}

protocol ImageTargetType {
    func process(_ data: Data)
}

protocol NewsfeedCellModelDelegate: class {
    func calculateTextArea(text: String, width: CGFloat) -> TextArea
    func reloadCell(model: NewsfeedCellModel)
    func loadImage(link: String, target: ImageTargetType)
}

class NewsfeedCellModel {
    
    let news: News
    
    let date: String
    
    let likesCounter: String
    let commentsCounter: String
    let shareCounter: String
    let viewsCounter: String
    
    weak var delegate: NewsfeedCellModelDelegate?
    
    var indexPath = IndexPath(item: 0, section: 0)
    
    var textAreaState: TextAreaState = .short
    var textHeight = CGFloat(0)
    
    private let textLineLimit = CGFloat(6)
    private var textArea = TextArea(width: 0, height: 0, lineHeight: 0)
    
    init(news: News) {
        self.news = news
        self.date = Formatter.shared.f(news.date)
        
        self.likesCounter = Formatter.shared.f(news.likes)
        self.commentsCounter = Formatter.shared.f(news.comments)
        self.shareCounter = Formatter.shared.f(news.reposts)
        self.viewsCounter = Formatter.shared.f(news.views)
    }
    
    @objc func handleButton() {
        if self.textAreaState == .short {
            self.textAreaState = .full
            self.textHeight = self.textArea.height
            
            self.delegate?.reloadCell(model: self)
        }
    }
    
    func loadImage(link: String, target: ImageTargetType) {
        self.delegate?.loadImage(link: link, target: target)
    }
    
    func height(_ width: CGFloat) -> CGFloat {
        if self.textArea.height == 0 {
            guard let f = self.delegate else { fatalError() }
            let textWidth = width - CellFrame.margin.left - CellFrame.margin.right
            self.textArea = f.calculateTextArea(text: self.news.text, width: textWidth)
            
            let lines = ceil(self.textArea.height / self.textArea.lineHeight)
            if lines > self.textLineLimit {
                self.textAreaState = .short
                self.textHeight = self.textLineLimit * self.textArea.lineHeight
            } else {
                self.textAreaState = .full
                self.textHeight = self.textArea.height
            }
        }
        
        let buttonHeight = self.textAreaState == .none ? 0 : CellFrame.buttonHeight
        
        let imageAreaHeight: CGFloat
        switch self.news.attachments.count {
        case 0:
            imageAreaHeight = 0
            break
        case 1:
            imageAreaHeight = CellFrame.imageHeight
            break
        default:
            imageAreaHeight = CellFrame.galleryHeight
            break
        }
        
        return CellFrame.margin.top
            + CellFrame.headerHeight
            + CellFrame.textTopMargin + self.textHeight + buttonHeight
            + CellFrame.imageTopMargin + imageAreaHeight
            + CellFrame.footerTopMargin + CellFrame.footerHeight
            + CellFrame.margin.bottom
    }
}

extension NewsfeedCellModel {
    static func create(news: News, delegate: NewsfeedCellModelDelegate) -> NewsfeedCellModel {
        let result = NewsfeedCellModel(news: news)
        result.delegate = delegate
        return result
    }
}

struct CollectionInsert {
    var path: [IndexPath]
    var action: () -> ()
}

class NewsfeedViewModel: NewsfeedCellModelDelegate {
    
    var onInsert: ((CollectionInsert) -> ())?
    
    var onUpdate: ((Bool) -> ())?
    
    var onCellUpdate: ((IndexPath) -> ())?
    
    var textAreaBlock: TextAreaBlock?
    
    var cellsCount: Int {
        return self.cells.count
    }
    
    private var cells = [NewsfeedCellModel]()
    
    private let webService: WebServiceType
    
    private var query = NewsfeedQuery.begin()
    
    private enum State {
        case idle, loading
    }
    
    private var state = State.idle
    
    init(webService: WebServiceType) {
        self.webService = webService
    }
    
    func getCellModel(_ index: Int) -> NewsfeedCellModel {
        return self.cells[index]
    }
    
    func refresh() {
        if self.state != .idle {
            return
        }
        self.state = .loading
        
        self.query = NewsfeedQuery.begin()
        
        self.webService.getNewsfeed(query: self.query, success: { [weak self] newsfeed in
            self?.update(newsfeed)
        }) { [weak self] error in
            print("NewsfeedViewModel: fail to refresh newsfeed: \(error)")
            self?.update(nil)
        }
    }
    
    func loadNext() {
        if self.state != .idle {
            return
        }
        self.state = .loading
        
        self.webService.getNewsfeed(query: self.query, success: { [weak self] newsfeed in
            self?.insert(newsfeed)
        }) { [weak self] error in
            print("NewsfeedViewModel: fail to load next: \(error)")
            self?.state = .idle
        }
    }
    
    func getUser(callback: @escaping (User) -> ()) {
        self.webService.getUser(success: { user in
            callback(user)
        }) { error in
            print("NewsfeedViewModel: fail to load user: \(error)")
        }
    }
    
    private func update(_ newsfeed: Newsfeed?) {
        if let p = newsfeed {
            self.query.nextFrom = p.nextFrom
            
            self.cells.removeAll()
            self.cells = p.news.map { NewsfeedCellModel.create(news: $0, delegate: self) }
            
            onUpdate?(true)
        } else {
            onUpdate?(false)
        }
        
        self.state = .idle
    }
    
    private func insert(_ newsfeed: Newsfeed) {
        self.query.nextFrom = newsfeed.nextFrom
        
        let start = self.cells.count
        
        var path = [IndexPath]()
        for i in 0..<newsfeed.news.count {
            path.append(IndexPath(item: start + i, section: 0))
        }
        
        let insert = CollectionInsert(path: path) {
            self.cells.append(contentsOf: newsfeed.news.map { NewsfeedCellModel.create(news: $0, delegate: self) })
        }
        
        onInsert?(insert)
        self.state = .idle
    }
}

extension NewsfeedViewModel {
    func calculateTextArea(text: String, width: CGFloat) -> TextArea {
        guard let block = self.textAreaBlock else { fatalError() }
        return block(text, width)
    }
    
    func reloadCell(model: NewsfeedCellModel) {
        self.onCellUpdate?(model.indexPath)
    }
    
    func loadImage(link: String, target: ImageTargetType) {
        self.webService.loadImage(link: link, success: { data in
            target.process(data)
        }) { error in
            print("NewsfeedViewModel: fail to load image: \(error)")
        }
    }
}

class NewsfeedViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private let viewModel: NewsfeedViewModel
    
    private let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: Layout())
    
    private let refreshControl = UIRefreshControl()
    
    init(viewModel: NewsfeedViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
        
        bindViewModel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(GradientView(frame: self.view.bounds))
        
        self.collectionView.frame = self.view.bounds
        self.collectionView.backgroundColor = UIColor.clear
        self.collectionView.alwaysBounceVertical = true
        self.view.addSubview(self.collectionView)
        
        self.collectionView.register(NewsfeedCell.self, forCellWithReuseIdentifier: NewsfeedCell.identifier)
        self.collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                     withReuseIdentifier: HeaderView.identifier)
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        
        self.refreshControl.addTarget(self, action: #selector(performRefresh), for: .valueChanged)
        self.collectionView.addSubview(self.refreshControl)
        
        self.viewModel.loadNext()
    }
    
    private func bindViewModel() {
        self.viewModel.onInsert = { [weak self] insert in
            self?.performInsert(insert)
        }
        
        self.viewModel.onUpdate = { [weak self] success in
            if success {
                self?.collectionView.reloadData()
            }
            self?.refreshControl.endRefreshing()
        }
        
        self.viewModel.onCellUpdate = { [weak self] indexPath in
            self?.collectionView.reloadItems(at: [indexPath])
        }
        
        self.viewModel.textAreaBlock = { (text, width) in
            let size = CGSize(width: width, height: CGFloat(Float.infinity))
            let font = UIFont.systemFont(ofSize: 15)
            let textSize = NSString(string: text).boundingRect(with: size,
                                                               options: .usesLineFragmentOrigin,
                                                               attributes: [NSAttributedString.Key.font: font],
                                                               context: nil)
            
            return TextArea(width: width, height: textSize.height, lineHeight: font.lineHeight)
        }
    }
    
    private func performInsert(_ insert: CollectionInsert) {
        self.collectionView.performBatchUpdates({
            insert.action()
            self.collectionView.insertItems(at: insert.path)
        }) { success in
            // TODO
        }
    }
    
    @objc private func performRefresh() {
        self.viewModel.refresh()
    }
}

extension NewsfeedViewController {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.cellsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsfeedCell.identifier, for: indexPath) as? NewsfeedCell else {
            fatalError()
        }
        
        if self.viewModel.cellsCount - indexPath.item < 5 {
            self.viewModel.loadNext()
        }
        
        let model = self.viewModel.getCellModel(indexPath.item)
        model.indexPath = indexPath
        cell.bindViewModel(model)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderView.identifier, for: indexPath) as? HeaderView else {
            fatalError()
        }
        
        self.viewModel.getUser { [weak self] user in
            let target = AvatarImageTarget(version: 0) { version, image in
                view.image = image
            }
            self?.viewModel.loadImage(link: user.imageLink, target: target)
        }
        
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.inset(by: collectionView.layoutMargins).width
        let height = self.viewModel.getCellModel(indexPath.row).height(width)
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 0, height: 36)
    }
}

private class Layout: UICollectionViewFlowLayout {
    
    override func prepare() {
        super.prepare()
        
        self.scrollDirection = .vertical
        self.sectionInset = UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0)
    }
}

class GradientView: UIView {
    
    private static let c1 = UIColor.colorFromString("#F7F9FA")
    private static let c2 = UIColor.colorFromString("#EBEDF0")
    
    private let gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
        self.gradientLayer.colors = [GradientView.c1.cgColor, GradientView.c2.cgColor]
        self.layer.addSublayer(self.gradientLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.gradientLayer.frame = self.bounds
    }
}

private class HeaderView: UICollectionReusableView {
    
    var image: UIImage? {
        didSet {
            self.imageView.image = self.image
        }
    }
    
    static let identifier = "HeaderView"
    
    private let searchBar = UISearchBar()
    
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
        self.searchBar.searchBarStyle = .minimal
        self.searchBar.placeholder = "Поиск"
        addSubview(self.searchBar)
        
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.clipsToBounds = true
        addSubview(self.imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let margins = self.layoutMargins
        
        let size = self.frame.height
        let x = self.frame.width - margins.right - size
        self.imageView.frame = CGRect(x: x, y: 0, width: size, height: size)
        
        self.searchBar.frame = CGRect(x: 0, y: 0, width: x - 10, height: self.frame.height)
    }
}
