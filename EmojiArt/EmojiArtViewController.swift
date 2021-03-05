//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Julea Parkhomava on 2/28/21.
//

import UIKit


extension EmojiArt.EmojiInfo{
    init?(label: UILabel){
        if let attributedString = label.attributedText, let font = attributedString.font{
            x = Int(label.center.x)
            y = Int(label.center.y)
            text = attributedString.string
            size = Int(font.pointSize)
        }else{
            return nil
        }
    }
}

class EmojiArtViewController: UIViewController, UIDropInteractionDelegate, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    //MARK: - Model
    //It's computed because model always will be sync with UI
    var emojiArt: EmojiArt?{
        get{
            if let url = emojiArtViewBackgroundImage.url{
                let emojies = emojiArtView.subviews.flatMap{$0 as? UILabel}.flatMap{EmojiArt.EmojiInfo(label: $0)}
                return EmojiArt(url: url, emojis: emojies)
            }else{
                return nil
            }
        }
        set{
            emojiArtViewBackgroundImage = (nil, nil)
            emojiArtView.subviews.flatMap{$0 as? UILabel}.forEach{
                $0.removeFromSuperview()
            }
            if let url = newValue?.url{
                imageFetcher = ImageFetcher(fetch: url){ (url, image) in
                    DispatchQueue.main.async {
                        self.emojiArtViewBackgroundImage = (url, image)
                        newValue?.emojis.forEach{
                            let attributedString = $0.text.attributedString(withTextStyle: .body, ofSize: CGFloat(($0.size)))
                            self.emojiArtView.addLabel(with: attributedString, centeredAt: CGPoint(x: $0.x, y: $0.y))
                        }
                    }
                }
            }
        }
    }
    
    
    @IBOutlet weak var dropZone: UIView!{
        didSet{
            dropZone.addInteraction(UIDropInteraction(delegate: self))
        }
    }
    
    @IBOutlet weak var scrollView: UIScrollView!{
        didSet{
            scrollView.minimumZoomScale = 0.1
            scrollView.maximumZoomScale = 5
            scrollView.delegate = self
            scrollView.addSubview(emojiArtView)
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return emojiArtView
    }
    
    private var emojiArtView = EmojiArtView()
    
    //underbar because we will never set this var, only through emojiArtBackImage
    private var _emojiArtBackgroundImageURL: URL?
    
    var emojiArtViewBackgroundImage: (url: URL?, image:UIImage?){
        get{
            (_emojiArtBackgroundImageURL, emojiArtView.backgroundImage)
        }
        set{
            scrollView?.zoomScale = 1.0
            emojiArtView.backgroundImage = newValue.image
            _emojiArtBackgroundImageURL = newValue.url
            let size = newValue.image?.size ?? CGSize.zero
            emojiArtView.frame = CGRect(origin: CGPoint.zero, size: size)
            scrollView.contentSize = size
            if let dropZone = self.dropZone, size.width > 0, size.height > 0{
                scrollView?.zoomScale = max(dropZone.bounds.size.width / size.width, dropZone.bounds.size.height)
            }
        }
    }
    
    
    @IBOutlet weak var emojiCollectionView: UICollectionView!{
        didSet{
            emojiCollectionView.dataSource = self
            emojiCollectionView.delegate = self
            emojiCollectionView.dragDelegate = self
            emojiCollectionView.dropDelegate = self
        }
    }
    
    var emojies = "❤️🐶🐥🐒🦊🍋🥭🥒🥑🥦🧄🌠🌄🌇🌌🌉🌅🛤".map{String($0)}
    
    private var addingEmoji = false
      
    
    @IBAction func addEmoji(_ sender: Any) {
        addingEmoji = true
        emojiCollectionView.reloadData()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section{
        case 0:
            return 1
        case 1:
            return emojies.count
        default:
            return 0
        }
        
    }
    
    private var font: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(64))
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 1{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "emojiCell", for: indexPath)
            if let emojiCell = cell as? EmojiCollectionViewCell {
                let text = NSAttributedString(string: emojies[indexPath.item], attributes: [.font: font])
                emojiCell.label.attributedText = text
            }
            return cell
        }else if addingEmoji{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiInputCell", for: indexPath)
            if let inputCell = cell as? TextFieldCollectionViewCell{
                inputCell.resignationHandler = { [weak self, unowned inputCell] in
                    if let text = inputCell.textField.text{
                        self?.emojies = (text.map{String($0)} + self!.emojies).uniquified
                    }
                    self?.addingEmoji = false
                    self?.emojiCollectionView.reloadData()
                }
            }
            return cell
        }else{
            return collectionView.dequeueReusableCell(withReuseIdentifier: "AddEmojiButtonCell", for: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 && addingEmoji{
            return CGSize(width: 300, height: 80)
        }else{
            return CGSize(width: 80, height: 80)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let inputCell = cell as? TextFieldCollectionViewCell{
            //when cell comes up, keyboard comes up
            inputCell.textField.becomeFirstResponder()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }
    
    func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        if !addingEmoji, let attributedString = (emojiCollectionView.cellForItem(at: indexPath) as? EmojiCollectionViewCell)?.label?.attributedText{
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: attributedString))
            dragItem.localObject = attributedString
            return [dragItem]
        }
        else{
            return []
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if let indexPath = destinationIndexPath, indexPath.section == 1{
            let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
            return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent:  .insertAtDestinationIndexPath)
        }
        else {
            return UICollectionViewDropProposal(operation: .cancel)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndex = coordinator.destinationIndexPath ?? IndexPath(row: 0, section: 0)
        for item in coordinator.items{
            if let sourceIndexPath = item.sourceIndexPath{
                if let attributedString = item.dragItem.localObject as? NSAttributedString{
                    collectionView.performBatchUpdates{
                        emojies.remove(at: sourceIndexPath.item)
                        emojies.insert(attributedString.string, at: destinationIndex.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndex])
                    }
                    coordinator.drop(item.dragItem, toItemAt: destinationIndex)
                }
            }else{
                let placeholderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndex, reuseIdentifier: "DropPlaceholderCell"))
                item.dragItem.itemProvider.loadObject(ofClass: NSAttributedString.self){ (provider, error) in
                    DispatchQueue.main.async {
                        if let attributedString = provider as? NSAttributedString{
                            placeholderContext.commitInsertion
                            { insertionIndexPath in
                                self.emojies.insert(attributedString.string, at: insertionIndexPath.item)
                            }
                        }
                        
                    }
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    var imageFetcher: ImageFetcher!
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession){
        imageFetcher = ImageFetcher(){(url,image) in
            DispatchQueue.main.async {
                self.emojiArtViewBackgroundImage = (url, image)
            }}
        session.loadObjects(ofClass: NSURL.self){ nsurl in
            if let url = nsurl.first as? URL{
                self.imageFetcher.fetch(url)
            }
        }
        session.loadObjects(ofClass: UIImage.self){images in
            if let image = images.first as? UIImage{
                self.imageFetcher.backup = image
            }
        }
    }
}
