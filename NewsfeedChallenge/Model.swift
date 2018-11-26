//
//  Model.swift
//  NewsfeedChallenge
//
//  Created by  Ivan Ushakov on 11/11/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import Foundation

struct User {
    var imageLink: String
}

extension User {
    static func transform(_ object: Dictionary<String, Any>) throws -> User {
        guard let response = object["response"] as? Array<Dictionary<String, Any>> else {
            throw WebServiceError()
        }
        
        guard let user = response.first else {
            throw WebServiceError()
        }
        
        guard let imageLink = user["photo_100"] as? String else {
            throw WebServiceError()
        }
        
        return User(imageLink: imageLink)
    }
}

struct Source {
    var id: Int64
    var name: String
    var imageLink: String
}

extension Source {
    static func fromGroup(_ object: Dictionary<String, Any>) throws -> Source {
        guard let id = object["id"] as? Int64 else {
            throw WebServiceError()
        }
        
        guard let name = object["name"] as? String else {
            throw WebServiceError()
        }
        
        guard let imageLink = object["photo_100"] as? String else {
            throw WebServiceError()
        }
        
        return Source(id: id, name: name, imageLink: imageLink)
    }
    
    static func fromProfile(_ object: Dictionary<String, Any>) throws -> Source {
        guard let id = object["id"] as? Int64 else {
            throw WebServiceError()
        }
        
        guard let firstName = object["first_name"] as? String else {
            throw WebServiceError()
        }
        
        guard let lastName = object["last_name"] as? String else {
            throw WebServiceError()
        }
        
        guard let imageLink = object["photo_100"] as? String else {
            throw WebServiceError()
        }
        
        return Source(id: id, name: firstName + " " + lastName, imageLink: imageLink)
    }
    
    static func transform(array: Array<Dictionary<String, Any>>, isGroup: Bool) throws -> Dictionary<Int64, Source> {
        var result = Dictionary<Int64, Source>()
        try array.forEach { object in
            let source = isGroup ? try Source.fromGroup(object) : try Source.fromProfile(object)
            result[source.id] = source
        }
        return result
    }
}

class SourceStore {
    
    private let profiles: Dictionary<Int64, Source>
    
    private let groups: Dictionary<Int64, Source>
    
    init(profiles: Dictionary<Int64, Source>, groups: Dictionary<Int64, Source>) {
        self.profiles = profiles
        self.groups = groups
    }
    
    func find(_ id: Int64) -> Source? {
        if (id > 0) {
            return self.profiles[id]
        } else {
            return self.groups[-1 * id]
        }
    }
}

struct Attachment {
    var imageLink: String
}

extension Attachment {
    static func transform(_ object: Dictionary<String, Any>) throws -> Attachment? {
        guard let type = object["type"] as? String else {
            throw WebServiceError()
        }
        
        if type != "photo" {
            return nil
        }
        
        guard let photo = object["photo"] as? Dictionary<String, Any> else {
            throw WebServiceError()
        }
        
        guard let sizes = photo["sizes"] as? Array<Dictionary<String, Any>> else {
            throw WebServiceError()
        }
        
        let p: (Dictionary<String, Any>) throws -> Bool = { object in
            guard let type = object["type"] as? String else {
                throw WebServiceError()
            }
            return type == "r"
        }
        
        guard let size = try sizes.first(where: { try p($0) }) else {
            return nil
        }
        
        guard let imageLink = size["url"] as? String else {
            throw WebServiceError()
        }
        
        return Attachment(imageLink: imageLink)
    }
}

struct News {
    var source: Source
    var date: Date
    var text: String
    var attachments: [Attachment]
    var likes: Int
    var comments: Int
    var reposts: Int
    var views: Int
}

extension News {
    static func transform(object: Dictionary<String, Any>, store: SourceStore) throws -> News {
        guard let id = object["source_id"] as? Int64, let source = store.find(id) else {
            throw WebServiceError()
        }
        
        guard let dateValue = object["date"] as? Int64 else {
            throw WebServiceError()
        }
        
        guard let text = object["text"] as? String else {
            throw WebServiceError()
        }
        
        guard let attachments = object["attachments"] as? Array<Dictionary<String, Any>>? else {
            throw WebServiceError()
        }
        
        guard let likesObject = object["likes"] as? Dictionary<String, Any>,
            let likes = likesObject["count"] as? Int else {
                throw WebServiceError()
        }
        
        guard let commentsObject = object["comments"] as? Dictionary<String, Any>,
            let comments = commentsObject["count"] as? Int else {
                throw WebServiceError()
        }
        
        guard let repostsObject = object["reposts"] as? Dictionary<String, Any>,
            let reposts = repostsObject["count"] as? Int else {
                throw WebServiceError()
        }
        
        guard let viewsObject = object["views"] as? Dictionary<String, Any>,
            let views = viewsObject["count"] as? Int else {
                throw WebServiceError()
        }
        
        return News(source: source,
                    date: Date(timeIntervalSince1970: TimeInterval(dateValue)),
                    text: text,
                    attachments: try (attachments ?? []).compactMap { try Attachment.transform($0) },
                    likes: likes,
                    comments: comments,
                    reposts: reposts,
                    views: views)
    }
}

struct Newsfeed {
    var news: [News]
    var nextFrom: String?
}

extension Newsfeed {
    static func transform(_ object: Dictionary<String, Any>) throws -> Newsfeed {
        guard let response = object["response"] as? Dictionary<String, Any> else {
            throw WebServiceError()
        }
        
        guard let itemsObject = response["items"] as? Array<Dictionary<String, Any>> else {
            throw WebServiceError()
        }
        
        guard let profilesObject = response["profiles"] as? Array<Dictionary<String, Any>> else {
            throw WebServiceError()
        }
        
        guard let groupsObject = response["groups"] as? Array<Dictionary<String, Any>> else {
            throw WebServiceError()
        }
        
        guard let nextFrom = response["next_from"] as? String? else {
            throw WebServiceError()
        }
        
        let profiles = try Source.transform(array: profilesObject, isGroup: false)
        let groups = try Source.transform(array: groupsObject, isGroup: true)
        let store = SourceStore(profiles: profiles, groups: groups)
        
        return Newsfeed(news: try itemsObject.map { try News.transform(object: $0, store: store) },
                        nextFrom: nextFrom)
    }
}
