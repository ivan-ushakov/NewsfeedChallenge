//
//  GalleryView.swift
//  NewsfeedChallenge
//
//  Created by  Ivan Ushakov on 11/11/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import UIKit

class GalleryView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private static let c1 = UIColor.colorFromString("#D7D8D9")
    
    var version = 0
    
    var loader: ((String, ImageTarget) -> ())?
    
    var items = [String]() {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: Layout())
    
    private let lineView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
        self.collectionView.backgroundColor = UIColor.clear
        self.collectionView.isPagingEnabled = true
        self.collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.identifier)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        addSubview(self.collectionView)
        
        self.lineView.backgroundColor = GalleryView.c1
        addSubview(self.lineView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = self.frame.width
        self.collectionView.frame = CGRect(x: 0, y: 0, width: width, height: 251)
        
        let lineHeight = CGFloat(0.5)
        self.lineView.frame = CGRect(x: 0, y: self.frame.height - lineHeight, width: width, height: lineHeight)
    }
}

extension GalleryView {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.identifier, for: indexPath) as? ImageCell else {
            fatalError()
        }
        
        let target = ImageTarget(version: self.version) { [weak self] version, image in
            guard let this = self else { return }
            if version == this.version {
                cell.image = image
            }
        }
        self.loader?(self.items[indexPath.item], target)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView.bounds.width == 0 {
            return .zero
        }
        
        let width = collectionView.bounds.width - 12
        return CGSize(width: width, height: collectionView.frame.height)
    }
}

private class Layout: UICollectionViewFlowLayout {
    
    override func prepare() {
        super.prepare()
        
        self.scrollDirection = .horizontal
        self.minimumInteritemSpacing = 4
        self.minimumLineSpacing = 4
    }
}

private class ImageCell: UICollectionViewCell {
    
    static let identifier = "ImageCell"
    
    var image: UIImage? {
        didSet {
            self.imageView.image = self.image
        }
    }
    
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.imageView.backgroundColor = UIColor.clear
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
        self.contentView.addSubview(self.imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func prepareForReuse() {
        self.imageView.image = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.frame = self.contentView.bounds
    }
}
