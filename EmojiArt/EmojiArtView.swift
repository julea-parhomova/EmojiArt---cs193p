//
//  EmojiArtView.swift
//  EmojiArt
//
//  Created by Julea Parkhomava on 2/28/21.
//

import UIKit

class EmojiArtView: UIView, UIDropInteractionDelegate {

    var backgroundImage: UIImage?{
        didSet{
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        backgroundImage?.draw(in: bounds)
    }
    
    override init(frame: CGRect){
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup(){
        addInteraction(UIDropInteraction(delegate: self))
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        session.loadObjects(ofClass: NSAttributedString.self){ providers in
            let dropPoint = session.location(in: self)
            for attributedString in (providers as? [NSAttributedString] ?? []){
                self.addLabel(with: attributedString, centeredAt: dropPoint)
            }
        }
    }
    
    func addLabel(with attributedString: NSAttributedString, centeredAt point: CGPoint){
        let label = UILabel()
        label.attributedText = attributedString
        label.center = point
        label.backgroundColor = .clear
        label.sizeToFit()
        self.addSubview(label)
    }
}
