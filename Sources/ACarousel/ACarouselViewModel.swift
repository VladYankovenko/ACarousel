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

import Combine
import SwiftUI

@available(iOS 13.0, OSX 10.15, *)
class ACarouselViewModel<Data, ID>: ObservableObject where Data: RandomAccessCollection, Data.Index == Int,
                                                            ID == Data.Element.ID, Data.Element: Identifiable {

    // MARK: - Published Properties

    /// The index of the currently active subview.
    @Published var activeIndex: Int = 0
    /// Offset x of the view drag.

    @Published var dragOffset: CGFloat = .zero

    // MARK: - Public Properties

    var data: Data {
        _data
    }

    var spacing: CGFloat {
        return _spacing
    }

    var headspace: CGFloat {
        return _headspace
    }

    var itemWidth: CGFloat {
        return viewSize.width - defaultPadding * 2
    }

    var itemWidthAbsolutle: CGFloat {
        return itemActualWidth
    }

    // MARK: - Private Properties

    private let _data: Data
    @Binding
    private var id: ID
    private let _spacing: CGFloat
    private let _headspace: CGFloat

    /// size of GeometryProxy
    var viewSize: CGSize = .zero

    // MARK: - Initialization

    init(
        _ data: Data,
        id: Binding<ID>,
        spacing: CGFloat,
        headspace: CGFloat
    ) {
        self._data = data
        self._id = id
        self._spacing = spacing
        self._headspace = headspace
        setActive(index: data.firstIndex(where: { $0.id == id.wrappedValue }) ?? .zero)
    }

    // MARK: - Public Methods

    func update(size: CGSize) {
        viewSize = size
    }

}

extension ACarouselViewModel {

}

// MARK: - private variable

extension ACarouselViewModel {

    private var defaultPadding: CGFloat {
        return _headspace + spacing
    }

    private var itemActualWidth: CGFloat {
        itemWidth + spacing
    }

}

// MARK: - Offset Method

extension ACarouselViewModel {
    /// current offset value
    var offset: CGFloat {
        let activeOffset = CGFloat(activeIndex) * itemActualWidth
        return defaultPadding - activeOffset
    }

}

// MARK: - Drag Gesture

extension ACarouselViewModel {
    /// drag gesture of view
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged(dragChanged)
            .onEnded(dragEnded)
    }

    private func dragChanged(_ value: DragGesture.Value) {

        /// Defines the maximum value of the drag
        /// Avoid dragging more than the values of multiple subviews at the end of the drag,
        /// and still only one subview is toggled
        var offset: CGFloat = itemActualWidth
        var translationWidth: CGFloat = value.translation.width

        if activeIndex == .zero, translationWidth > .zero {
            translationWidth = rubberBandClamp(translationWidth, maxOffset: itemWidth / 2)
        }

        if activeIndex == _data.count - 1, translationWidth < .zero {
            translationWidth = rubberBandClamp(translationWidth, maxOffset: itemWidth / 2)
        }

        if value.translation.width > 0 {
            offset = min(offset, translationWidth)
        } else {
            offset = max(-offset, translationWidth)
        }

        /// set drag offset
        dragOffset = offset
    }

    private func dragEnded(_ value: DragGesture.Value) {
        let dragThreshold: CGFloat = itemWidth / 4
        let velocityThreshold: CGFloat = 500 // можно подстроить под нужную чувствительность

        let predictedEndOffset = value.predictedEndTranslation.width
        let dragVelocity = value.velocity.width

        var activeIndex = self.activeIndex

        if predictedEndOffset > dragThreshold || dragVelocity > velocityThreshold {
            activeIndex -= 1
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                dragOffset = .zero
                setActive(index: activeIndex)
            }
        } else if predictedEndOffset < -dragThreshold || dragVelocity < -velocityThreshold {
            activeIndex += 1
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                dragOffset = .zero
                setActive(index: activeIndex)
            }
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                dragOffset = .zero
            }
        }
    }

    private func rubberBandClamp(_ offset: CGFloat, maxOffset: CGFloat) -> CGFloat {
        let stiffness: CGFloat = 0.5
        let sign = offset < 0 ? -1.0 : 1.0
        let absOffset = abs(offset)
        let x = absOffset / maxOffset
        let clampedX = maxOffset * (1.0 - 1.0 / (x * stiffness + 1.0))
        return sign * clampedX
    }

    func setActive(index: Int) {
        guard _data.indices.contains(index) else {
            return
        }
        activeIndex = index
        DispatchQueue.main.async(execute: {
            self.id = self._data[index].id
        })
    }

}
