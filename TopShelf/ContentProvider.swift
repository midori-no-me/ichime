//
//  ContentProvider.swift
//  TopShelf
//
//  Created by p.flaks on 29.03.2024.
//

import TVServices

class ContentProvider: TVTopShelfContentProvider {
    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        
        // Reply with a content object.
        let items = [makeCarouselItem(id: "1"), makeCarouselItem(id: "2")]

        var section = TVTopShelfItemCollection(items: items)
        section.title = "Серии к просмотру"
        let sections = [section]

        let content = TVTopShelfSectionedContent(sections: sections)

        completionHandler(content)
    }
}

private func makeCarouselItem(id: String) -> TVTopShelfSectionedItem {
    let item = TVTopShelfSectionedItem(identifier: id)

    item.title = "6 серия — Shin no Nakama ja Nai to Yuusha no Party wo Oidasareta node, Henkyou de Slow Life suru Koto ni Shimashita 2nd Season"
    item.setImageURL(URL(string: "https://anime365.ru/posters/31760.23724939004.jpg")!, for: .screenScale1x)
    item.setImageURL(URL(string: "https://anime365.ru/posters/31760.23724939004.jpg")!, for: .screenScale2x)
    item.imageShape = .poster
    item.playbackProgress = 0.5

    return item
}
