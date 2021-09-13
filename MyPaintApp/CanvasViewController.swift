//
//  ViewController.swift
//  MyPaintApp
//
//  Created by Daniel Yamrak on 13.09.2021.
//

import UIKit
import PencilKit
import PhotosUI

class CanvasViewController: UIViewController, PKCanvasViewDelegate, PKToolPickerObserver {

    @IBOutlet weak var canvasView: PKCanvasView!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!

    private var toolPicker: PKToolPicker!
    var drawing = PKDrawing()

    let canvasWidth: CGFloat = 768
    let canvasOverscrollHeight: CGFloat = 500

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        canvasView.delegate = self
        canvasView.drawing = drawing
        canvasView.alwaysBounceVertical = true

        toolPicker = PKToolPicker()
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        toolPicker.addObserver(self)
        updateLayout(for: toolPicker)
        canvasView.becomeFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let canvasScale = canvasView.bounds.width / canvasWidth
        canvasView.minimumZoomScale = canvasScale
        canvasView.maximumZoomScale = canvasScale
        canvasView.zoomScale = canvasScale
        updateContentSizeForDrawing()
        canvasView.contentOffset = CGPoint(x: 0, y: -canvasView.adjustedContentInset.top)
    }

    private func updateContentSizeForDrawing() {
        let drawing = canvasView.drawing
        let contentHeight: CGFloat

        // Adjust the content size to always be bigger than the drawing height.
        if !drawing.bounds.isNull {
            contentHeight = max(canvasView.bounds.height, (drawing.bounds.maxY + self.canvasOverscrollHeight) * canvasView.zoomScale)
        } else {
            contentHeight = canvasView.bounds.height
        }
        canvasView.contentSize = CGSize(width: canvasWidth * canvasView.zoomScale, height: contentHeight)
    }

    private func saveDrawingToPhotos() {
        UIGraphicsBeginImageContextWithOptions(canvasView.bounds.size, false, UIScreen.main.scale)

        canvasView.drawHierarchy(in: canvasView.bounds, afterScreenUpdates: true)

        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return }
        UIGraphicsEndImageContext()
        PHPhotoLibrary.shared().performChanges({PHAssetChangeRequest.creationRequestForAsset(from: image)

        }, completionHandler: { success, error in
            if error != nil {
                print("Something went wrong! The image hasn't been saved")
            } else {
                print("Success!!!")
            }
        })
    }

    private func clearCanvas() {
        canvasView.drawing = drawing
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    @IBAction func undoButtonPressed(_ sender: Any) {
        undoManager?.undo()
    }

    @IBAction func redoButtonPressed(_ sender: Any) {
        undoManager?.redo()
    }

    @IBAction func clearAllButtonPressed(_ sender: Any) {
        clearCanvas()
    }

    @IBAction func saveButtonPressed(_ sender: Any) {
        saveDrawingToPhotos()
    }

    // MARK: Tool Picker Observer

    func toolPickerFramesObscuredDidChange(_ toolPicker: PKToolPicker) {
        updateLayout(for: toolPicker)
    }

    func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {
        updateLayout(for: toolPicker)
    }

    func updateLayout(for toolPicker: PKToolPicker) {
        let obscuredFrame = toolPicker.frameObscured(in: view)

        // If the tool picker is floating over the canvas, it also contains
        // undo and redo buttons.
        if obscuredFrame.isNull {
            canvasView.contentInset = .zero
//            navigationItem.leftBarButtonItems = []
        }
        canvasView.scrollIndicatorInsets = canvasView.contentInset
    }


}
