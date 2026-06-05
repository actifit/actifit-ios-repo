//
//  BannerImageCell.swift
//  Actifit
//
//  Created by Ali Jaber on 21/07/2023.
//

import UIKit
import Combine
class BannerImageCell: UICollectionViewCell {
    var titleLabel = UILabel()
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var bannerImageView: UIImageView!
    private var cancellable: AnyCancellable?
    private static let imageCache = NSCache<NSString, UIImage>()
    var onGradientTap: ((String?)->())?
    var bannerObject: BannerImageModel? {
        didSet {
            setUI()
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        let gesture = UITapGestureRecognizer(target: self, action: #selector(openLink))
        bannerImageView.addGestureRecognizer(gesture)
        bannerImageView.isUserInteractionEnabled = true
        // Initialization code
    }
    
    private func setUI() {
        titleLabel.text = ""
        bannerImageView.image = nil
        guard let banner = bannerObject else { return }
        getImage(url: banner.featuredImageUrl ?? "")
    }
    
    private func getImage(url: String) {
        
        let imgURL = URL(string: url)
        if let cachedImage = BannerImageCell.imageCache.object(forKey: url as NSString) {
            // If the image is cached, use it directly
            bannerImageView.image = cachedImage
            setLabel()
        } else {
          guard imgURL != nil else { return }
            // cancellable =
            cancellable = URLSession.shared.dataTaskPublisher(for: imgURL!)
                .map {data, _ -> UIImage? in
                    UIImage(data: data)
                }.receive(on: DispatchQueue.main)
                .replaceError(with: nil)
                .sink{[weak self ] image in
                    self?.bannerImageView.image = image
                    self?.addRedLayer()
                    guard let isImage = image else { return}
                    BannerImageCell.imageCache.setObject(isImage, forKey: url as NSString)
                    // self?.imageSubject.send(image)
                    //  self?.imageLoaderVisibilitySubject.send(false)
                }
            
        }
    }
    
    @objc func openLink() {
        onGradientTap?(bannerObject?.linkUrl)
    }
    
    private func addRedLayer() {
        let gradient = GradientView(frame: bannerImageView.frame)
        gradient.center = bannerImageView.center
        bannerImageView.addSubview(gradient)
        //containerView.insertSubview(gradient, at: 0)
       setLabel()
       
    }
    
    private func setLabel() {
        titleLabel.text = ""
        titleLabel = UILabel(frame: CGRect(x: 16, y: 16, width: containerView.frame.width - 32, height: 100))
        titleLabel.font = UIFont.italicSystemFont(ofSize: 26)
        titleLabel.text = bannerObject?.newsTitle
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        let attributes: [NSAttributedString.Key: Any] = [
                   .font: UIFont.systemFont(ofSize: 26).italicBold // Apply italic bold font
               ]
        let attributedText = NSAttributedString(string: bannerObject?.newsTitle ?? "", attributes: attributes)
        titleLabel.attributedText = attributedText
        containerView.addSubview(titleLabel)
    }
    

}
