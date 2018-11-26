//
//  NewsfeedCell.swift
//  NewsfeedChallenge
//
//  Created by  Ivan Ushakov on 09/11/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import UIKit

struct ImageTarget: ImageTargetType {
    
    var version: Int
    
    var target: ((Int, UIImage) -> ())?
    
    func process(_ data: Data) {
        guard let image = UIImage(data: data) else {
            return
        }
        
        DispatchQueue.main.async {
            self.target?(self.version, image)
        }
    }
}

struct AvatarImageTarget: ImageTargetType {
    
    var version: Int
    
    var target: ((Int, UIImage) -> ())?
    
    func process(_ data: Data) {
        if Thread.isMainThread {
            DispatchQueue.global().async { self.f(data) }
        } else {
            f(data)
        }
    }
    
    private func f(_ data: Data) {
        guard let source = UIImage(data: data) else {
            return
        }
        
        guard let p = source.cgImage else {
            return
        }
        
        guard let context = CGContext(data: nil,
                                      width: Int(source.size.width),
                                      height: Int(source.size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
        
        context.beginPath()
        let center = CGPoint(x: source.size.width / 2, y: source.size.height / 2)
        let radius = source.size.width / 2
        context.addArc(center: center, radius: radius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: false)
        context.closePath()
        context.clip()
        
        context.draw(p, in: CGRect(x: 0, y: 0, width: source.size.width, height: source.size.height))
        
        guard let p2 = context.makeImage() else {
            return
        }
        
        let target = UIImage(cgImage: p2)
        
        DispatchQueue.main.async {
            self.target?(self.version, target)
        }
    }
}

struct CellFrame {
    static let margin = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    
    static let headerHeight = CGFloat(36)
    
    static let textTopMargin = CGFloat(10)
    
    static let buttonHeight = CGFloat(22)
    
    static let imageTopMargin = CGFloat(6)
    static let imageHeight = CGFloat(269)
    static let galleryHeight = CGFloat(290)
    
    static let footerTopMargin = CGFloat(18)
    static let footerHeight = CGFloat(24)
}

class NewsfeedCell: UICollectionViewCell {
    
    static let identifier = "NewsfeedCell"
    
    private let backView = UIView()
    
    private let headerView = HeaderView()
    
    private let textLabel = UILabel()
    private let button = UILabel()
    
    private let imageView = UIImageView()
    private let galleryView = GalleryView()
    
    private let footerView = FooterView()
    
    private var version = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backView.backgroundColor = UIColor.white
        self.backView.layer.cornerRadius = 10
        self.contentView.addSubview(self.backView)
        
        self.contentView.addSubview(self.headerView)
        
        self.textLabel.font = UIFont.systemFont(ofSize: 15)
        self.textLabel.textColor = UIColor.black
        self.textLabel.textAlignment = .left
        self.textLabel.numberOfLines = 0
        self.textLabel.lineBreakMode = .byClipping
        self.contentView.addSubview(self.textLabel)
        
        self.button.font = UIFont.systemFont(ofSize: 15)
        self.button.textColor = UIColor.blue
        self.button.textAlignment = .left
        self.button.text = "Показать полностью..."
        self.contentView.addSubview(self.button)
        
        self.imageView.backgroundColor = UIColor.clear
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
        self.imageView.isHidden = true
        self.contentView.addSubview(self.imageView)
        
        self.galleryView.isHidden = true
        self.contentView.addSubview(self.galleryView)
        
        self.contentView.addSubview(self.footerView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func bindViewModel(_ viewModel: NewsfeedCellModel) {
        prepareHeaderArea(viewModel)
        prepareTextArea(viewModel)
        prepareImageArea(viewModel)
        prepareFooterArea(viewModel)
    }
    
    override func prepareForReuse() {
        self.imageView.image = nil
        self.imageView.isHidden = true
        
        if let r = self.button.gestureRecognizers?.first {
            self.button.removeGestureRecognizer(r)
        }
        
        self.version += 1
        
        self.galleryView.loader = nil
        self.galleryView.items = []
        self.galleryView.version += 1
        self.galleryView.isHidden = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.backView.frame = self.bounds
        
        let margin = CellFrame.margin
        let x = margin.left
        let width = self.contentView.frame.width - margin.left - margin.right
        
        var offset = margin.top
        self.headerView.frame = CGRect(x: x, y: offset, width: width, height: CellFrame.headerHeight)
        offset += CellFrame.headerHeight
        
        offset += CellFrame.textTopMargin
        self.textLabel.frame = CGRect(x: x, y: offset, width: width, height: self.textLabel.frame.height)
        offset += self.textLabel.frame.height
        
        if !self.button.isHidden {
            self.button.frame = CGRect(x: x, y: offset, width: width, height: CellFrame.buttonHeight)
            offset += CellFrame.buttonHeight
        }
        
        if !self.imageView.isHidden {
            offset += CellFrame.imageTopMargin
            let w = self.contentView.frame.width
            self.imageView.frame = CGRect(x: 0, y: offset, width: w, height: CellFrame.imageHeight)
            offset += CellFrame.imageHeight
        }
        
        if !self.galleryView.isHidden {
            offset += CellFrame.imageTopMargin
            let w = self.contentView.frame.width - margin.left
            self.galleryView.frame = CGRect(x: x, y: offset, width: w, height: CellFrame.galleryHeight)
            offset += CellFrame.galleryHeight
        }
        
        let footerHeight = CellFrame.footerHeight
        let footerOffset = self.contentView.frame.height - margin.bottom - footerHeight
        self.footerView.frame = CGRect(x: x, y: footerOffset, width: width, height: footerHeight)
    }
    
    private func prepareHeaderArea(_ viewModel: NewsfeedCellModel) {
        let target = AvatarImageTarget(version: self.version) { [weak self] version, image in
            guard let this = self else { return }
            if version == this.version {
                this.headerView.image = image
            }
        }
        viewModel.loadImage(link: viewModel.news.source.imageLink, target: target)
        
        self.headerView.name = viewModel.news.source.name
        self.headerView.date = viewModel.date
    }
    
    private func prepareTextArea(_ viewModel: NewsfeedCellModel) {
        self.textLabel.text = viewModel.news.text
        self.textLabel.frame = CGRect(x: 0, y: 0, width: 0, height: viewModel.textHeight)
        
        if viewModel.textAreaState == .short {
            self.button.isHidden = false
            self.button.addGestureRecognizer(UITapGestureRecognizer(target: viewModel, action: #selector(NewsfeedCellModel.handleButton)))
            self.button.isUserInteractionEnabled = true
        } else {
            self.button.isHidden = true
        }
    }
    
    private func prepareImageArea(_ viewModel: NewsfeedCellModel) {
        let attachments = viewModel.news.attachments
        
        if attachments.count == 1 {
            self.imageView.isHidden = false
            let target = ImageTarget(version: self.version) { [weak self] version, image in
                guard let this = self else { return }
                if version == this.version {
                    this.imageView.image = image
                }
            }
            viewModel.loadImage(link: attachments[0].imageLink, target: target)
            
            return
        }
        
        if attachments.count > 1 {
            self.galleryView.isHidden = false
            
            self.galleryView.loader = { link, target in
                viewModel.loadImage(link: link, target: target)
            }
            
            self.galleryView.items = attachments.map { $0.imageLink }
            return
        }
    }
    
    private func prepareFooterArea(_ viewModel: NewsfeedCellModel) {
        self.footerView.likesCounter = viewModel.likesCounter
        self.footerView.commentsCounter = viewModel.commentsCounter
        self.footerView.shareCounter = viewModel.shareCounter
        self.footerView.viewsCounter = viewModel.viewsCounter
    }
}

private class HeaderView: UIView {
    
    private static let c1 = UIColor.colorFromString("#2C2D2E")
    private static let c2 = UIColor.colorFromString("#818C99")
    
    var image: UIImage? {
        didSet {
            self.imageView.image = self.image
        }
    }
    
    var name: String? {
        didSet {
            self.nameLabel.text = self.name
        }
    }
    
    var date: String? {
        didSet {
            self.dateLabel.text = self.date
        }
    }
    
    private let imageView = UIImageView()
    
    private let nameLabel = UILabel()
    
    private let dateLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
        self.imageView.backgroundColor = UIColor.clear
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.clipsToBounds = true
        addSubview(self.imageView)
        
        self.nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        self.nameLabel.textColor = HeaderView.c1
        self.nameLabel.textAlignment = .left
        addSubview(self.nameLabel)
        
        self.dateLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.dateLabel.textColor = HeaderView.c2
        self.dateLabel.textAlignment = .left
        addSubview(self.dateLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        
        self.nameLabel.sizeToFit()
        self.dateLabel.sizeToFit()
        
        let leftMargin = CGFloat(10)
        let x = self.imageView.frame.maxX + leftMargin
        let y = floor((self.frame.height - self.nameLabel.frame.height - self.dateLabel.frame.height) / 2)
        let width = self.frame.width - self.imageView.frame.width - leftMargin
        
        self.nameLabel.frame = CGRect(x: x, y: y, width: width, height: self.nameLabel.frame.height)
        self.dateLabel.frame = CGRect(x: x, y: self.nameLabel.frame.maxY, width: width, height: self.dateLabel.frame.height)
    }
}

private class FooterView: UIView {
    
    private static let c1 = UIColor.colorFromString("#818C99")
    private static let c2 = UIColor.colorFromString("#A8ADB2")
    
    var likesCounter: String? {
        didSet {
            self.likesButton.setTitle(self.likesCounter, for: .disabled)
        }
    }
    
    var commentsCounter: String? {
        didSet {
            self.commentsButton.setTitle(self.commentsCounter, for: .disabled)
        }
    }
    
    var shareCounter: String? {
        didSet {
            self.shareButton.setTitle(self.shareCounter, for: .disabled)
        }
    }
    
    var viewsCounter: String? {
        didSet {
            self.viewsButton.setTitle(self.viewsCounter, for: .disabled)
        }
    }
    
    private let likesButton = UIButton(type: .custom)
    private let commentsButton = UIButton(type: .custom)
    private let shareButton = UIButton(type: .custom)
    private let viewsButton = UIButton(type: .custom)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
        self.likesButton.setImage(UIImage(named: "like_icon"), for: .normal)
        self.likesButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        self.likesButton.setTitleColor(FooterView.c1, for: .disabled)
        addSubview(self.likesButton)
        
        self.commentsButton.setImage(UIImage(named: "comment_icon"), for: .normal)
        self.commentsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        self.commentsButton.setTitleColor(FooterView.c1, for: .disabled)
        self.commentsButton.isEnabled = false
        addSubview(self.commentsButton)
        
        self.shareButton.setImage(UIImage(named: "share_icon"), for: .normal)
        self.shareButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        self.shareButton.setTitleColor(FooterView.c1, for: .disabled)
        addSubview(self.shareButton)
        
        self.viewsButton.setImage(UIImage(named: "view_icon"), for: .normal)
        self.viewsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        self.viewsButton.setTitleColor(FooterView.c2, for: .disabled)
        addSubview(self.viewsButton)
        
        let e1 = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        let e2 = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        
        [self.likesButton, self.commentsButton, self.shareButton, self.viewsButton].forEach { b in
            b.imageEdgeInsets = e1
            b.titleEdgeInsets = e2
            b.isEnabled = false
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = CGFloat(65)
        let height = CGFloat(24)
        
        self.likesButton.frame = CGRect(x: 0, y: 0, width: width, height: height)
        self.commentsButton.frame = CGRect(x: self.likesButton.frame.maxX, y: 0, width: width, height: height)
        self.shareButton.frame = CGRect(x: self.commentsButton.frame.maxX, y: 0, width: width, height: height)
        
        self.viewsButton.frame = CGRect(x: self.frame.width - width, y: 0, width: width, height: height)
    }
}
