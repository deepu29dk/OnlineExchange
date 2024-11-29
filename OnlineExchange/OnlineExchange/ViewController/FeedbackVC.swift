//
//  Feedback.swift
//  OnlineExchange
//
//  Created by Deepika Kunwar on 14/11/24.
//

import UIKit
import Cosmos
import FirebaseFirestore

class FeedbackVC: BaseViewController,UITextViewDelegate {
    @IBOutlet weak var cosmosViewFull: CosmosView!
    @IBOutlet weak var feedbackTextView: UITextView!
    var rating: Double = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        cosmosViewFull.didFinishTouchingCosmos = { [weak self] rating in
                   self?.rating = rating
               }
        
        feedbackTextView.delegate = self
        setupPlaceholder()
        
    }
    
    
    private func updateRating(requiredRating: Double?) {
        var newRatingValue: Double = 0
        
        if let nonEmptyRequiredRating = requiredRating {
            newRatingValue = nonEmptyRequiredRating
        } else {
            newRatingValue = 0
        }
        
        cosmosViewFull.rating = newRatingValue
    }
    
    
    private func didTouchCosmos(_ rating: Double) {
        updateRating(requiredRating: rating)
    }
    
    private func didFinishTouchingCosmos(_ rating: Double) {
    }
    
    
    func setupPlaceholder() {
        feedbackTextView.text = "Write your feedback here..."
        feedbackTextView.textColor = .lightGray
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Remove placeholder text when the user starts editing
        if textView.textColor == .lightGray {
            textView.text = ""
            textView.textColor = .black // or your preferred text color
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            setupPlaceholder()
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // Here you can update the UI based on changes if needed
        // Example: Enable a button if textView is not empty
    }
    
    
    @IBAction func submitRating(_ sender: UIButton) {
           guard let feedback = feedbackTextView.text, !feedback.isEmpty, feedback != "Write your feedback here..." else {
               showAlerOnTop(message: "Please provide feedback")
               return
           }
           
           // Prepare data to submit to Firestore
           let data: [String: Any] = [
               "rating": rating,
               "feedback": feedback,
               "timestamp": Timestamp(date: Date()),
               "userid": UserDefaultsManager.shared.getDocumentId()
           ]
           
           // Add to Firestore (assuming "Ratings" is the collection name)
           Firestore.firestore().collection("Ratings").addDocument(data: data) { error in
               if let error = error {
                   print("Error submitting rating: \(error)")
               } else {
                   showAlerOnTop(message: "Feedback Sent!")
                   
                   self.navigationController?.popToRootViewController(animated: true)
                   
               }
           }
       }
    
}
