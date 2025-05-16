/**
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import SwiftUI

@available(iOS 14.0, OSX 10.15, *)
public struct ACarousel<Data, ID, Content>: View where Data: RandomAccessCollection, Data.Index == Int,
                                                       ID == Data.Element.ID, Data.Element: Identifiable, Content: View {

    @ObservedObject
    private var viewModel: ACarouselViewModel<Data, ID>
    private let content: (Data.Element) -> Content

    @State private var progress: CGFloat = .zero

    public var body: some View {
        GeometryReader { proxy -> AnyView in
            viewModel.update(size: proxy.size)
            return AnyView(generateContent(proxy: proxy))
        }.clipped()
    }

    private func generateContent(proxy: GeometryProxy) -> some View {
        HStack(spacing: viewModel.spacing) {
            ForEach(Array(viewModel.data.enumerated()), id: \.element.id) { index, item in
                content(item)
                    .frame(width: viewModel.itemWidth)
                    .scaleEffect(0.8 + 0.2 * calculateProgress(for: index))
            }
        }
        .frame(
            height: proxy.size.height,
            alignment: .leading
        )
        .offset(x: viewModel.offset + viewModel.dragOffset)
        .contentShape(Rectangle())
        .gesture(viewModel.dragGesture)
        .onChange(of: viewModel.dragOffset) { newValue in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                calculateProgress()
            }
        }
        .onAppear() {
            calculateProgress()
        }
    }

    func calculateProgress() {
        let offset = -(viewModel.offset + viewModel.dragOffset) + (viewModel.spacing + viewModel.headspace)
        let progress = (offset / viewModel.itemWidthAbsolutle)
        self.progress = progress
    }

    func calculateProgress(for index: Int) -> CGFloat {
        let activeIndex = viewModel.activeIndex
        let diff = progress - CGFloat(activeIndex)
        if index == activeIndex {
            return 1 - abs(diff)
        } else if index == activeIndex - 1, diff <= 0 {
            return abs(diff)
        } else if index == activeIndex + 1, diff >= 0 {
            return abs(diff)
        }  else {
            return 0
        }
    }
}

// MARK: - Initializers

@available(iOS 14.0, OSX 10.15, *)
public extension ACarousel {

    /// Creates an instance that uniquely identifies and creates views across
    /// updates based on the identity of the underlying data.
    ///
    /// - Parameters:
    ///   - data: The data that the ``ACarousel`` instance uses to create views
    ///     dynamically.
    ///   - id: The key path to the provided data's identifier.
    ///   - index: The index of currently active.
    ///   - spacing: The distance between adjacent subviews, default is 10.
    ///   - headspace: The width of the exposed side subviews, default is 10
    ///   - sidesScaling: The scale of the subviews on both sides, limits 0...1,
    ///     default is 0.8.
    ///   - isWrap: Define views to scroll through in a loop, default is false.
    ///   - autoScroll: A enum that define view to scroll automatically. See
    ///     ``ACarouselAutoScroll``. default is `inactive`.
    ///   - content: The view builder that creates views dynamically.
    init(_ data: Data,
         id: Binding<ID>,
         spacing: CGFloat = 10,
         headspace: CGFloat = 10,
         @ViewBuilder content: @escaping (Data.Element) -> Content) {

        self.viewModel = ACarouselViewModel(
            data,
            id: id,
            spacing: spacing,
            headspace: headspace
        )
        self.content = content
    }

}

@available(iOS 14.0, OSX 11.0, *)
struct ACarousel_LibraryContent: LibraryContentProvider {


    let data = [
        Item(id: 1, color: .red),
        Item(id: 2, color: .green),
        Item(id: 3, color: .blue)
    ]

    @State var selecredId = 1

    @LibraryContentBuilder
    var views: [LibraryItem] {
        LibraryItem(
            ACarousel(
                data,
                id: $selecredId
            ) { _ in },
            title: "ACarousel",
            category: .control
        )
    }

    struct Item: Identifiable {
        let id: Int
        let color: Color
    }
}
