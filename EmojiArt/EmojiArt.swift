//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by Julea Parkhomava on 3/5/21.
//

import Foundation

struct EmojiArt: Codable {
    var url: URL?
    var emojis = [EmojiInfo]()
    
    struct EmojiInfo: Codable {
        var text: String
        var x: Int
        var y: Int
        var size: Int
        //Int and not CGFloat, because model is UI independent thing
        //Int and not Double – JSON looks better
    }
    
    var json: Data?{
        return try? JSONEncoder().encode(self)
    }
    
    init(url: URL, emojis: [EmojiInfo]){
        self.url = url
        self.emojis = emojis
    }
}
