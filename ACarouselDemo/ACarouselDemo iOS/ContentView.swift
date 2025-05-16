//
//  ContentView.swift
//  ACarouselDemo iOS
//
//  Created by Autumn on 2020/11/16.
//

import SwiftUI
import ACarousel
               
struct Item: Identifiable {
    let id: Int
    let image: Image
    let name: String
}

let names: [String] = [
    "Luffy", "Zoro", "Sanji", "Nami", "Usopp", "Chopper", "Robin", "Franky", "Brook"]

let roles: [Item] = names.enumerated().map { index, name in
    Item(id: index, image: Image(name), name: name)
}


struct ContentView: View {
    
    @State var spacing: CGFloat = 10
    @State var headspace: CGFloat = 10
    @State var currentId = 1

    var body: some View {
        VStack {
            Spacer().frame(height: 40)
            ACarousel(roles,
                      id: $currentId,
                      spacing: spacing,
                      headspace: headspace) { role in
                role.image
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .cornerRadius(30)
            }
            .frame(height: 300)
            Spacer()
            
            ControlPanel(spacing: $spacing,
                         headspace: $headspace)
            Spacer()
        }
        .onChange(of: currentId) { newValue in
            print(newValue)
        }
    }
}

struct ControlPanel: View {
    
    @Binding var spacing: CGFloat
    @Binding var headspace: CGFloat

    var body: some View {
        VStack {
            Group {
                HStack {
                    Text("spacing: ").frame(width: 120)
                    Slider(value: $spacing, in: 0...30, minimumValueLabel: Text("0"), maximumValueLabel: Text("30")) { EmptyView() }
                }
                HStack {
                    Text("headspace: ").frame(width: 120)
                    Slider(value: $headspace, in: 0...30, minimumValueLabel: Text("0"), maximumValueLabel: Text("30")) { EmptyView() }
                }
            }
        }
        .padding([.horizontal, .bottom])
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}




