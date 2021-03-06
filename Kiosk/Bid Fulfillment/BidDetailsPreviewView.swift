import UIKit
import Artsy_UILabels
import Artsy_UIButtons
import UIImageViewAligned
import RxSwift
import RxCocoa

class BidDetailsPreviewView: UIView {

    let _bidDetails = Variable<BidDetails?>(nil)
    var bidDetails: BidDetails? {
        didSet {
            self._bidDetails.value = bidDetails
        }
    }

    @objc dynamic let artworkImageView = UIImageViewAligned()
    @objc dynamic let artistNameLabel = ARSansSerifLabel()
    @objc dynamic let artworkTitleLabel = ARSerifLabel()
    @objc dynamic let currentBidPriceLabel = ARSerifLabel()

    override func awakeFromNib() {
        self.backgroundColor = .white

        artistNameLabel.numberOfLines = 1
        artworkTitleLabel.numberOfLines = 1
        currentBidPriceLabel.numberOfLines = 1

        artworkImageView.alignRight = true
        artworkImageView.alignBottom = true
        artworkImageView.contentMode = .scaleAspectFit

        artistNameLabel.font = UIFont.sansSerifFont(withSize: 14)
        currentBidPriceLabel.font = UIFont.serifBoldFont(withSize: 14)

        let artwork = _bidDetails
            .asObservable()
            .filterNil()
            .map { bidDetails in
                return bidDetails.saleArtwork?.artwork
            }
            .take(1)

        artwork
            .subscribe(onNext: { [weak self] artwork in
                if let url = artwork?.defaultImage?.thumbnailURL() {
                    self?.bidDetails?.setImage(url, self!.artworkImageView)
                } else {
                    self?.artworkImageView.image = nil
                }
            })
            .disposed(by: rx.disposeBag)

        artwork
            .map { artwork in
                return artwork?.artists?.first?.name
            }
            .map { name in
                return name ?? ""
            }
            .bind(to: artistNameLabel.rx.text)
            .disposed(by: rx.disposeBag)

        artwork
            .map { artwork -> NSAttributedString in
                guard let artwork = artwork else {
                    return NSAttributedString()
                }

                return artwork.titleAndDate
            }
            .mapToOptional()
            .bind(to: artworkTitleLabel.rx.attributedText)
            .disposed(by: rx.disposeBag)

        _bidDetails
            .asObservable()
            .filterNil()
            .take(1)
            .map { bidDetails in
                guard let cents = bidDetails.bidAmountCents.value else { return "" }
                guard let currencySymbol = bidDetails.saleArtwork?.currencySymbol else { return "" }

                return "Your bid: " + centsToPresentableDollarsString(cents.currencyValue, currencySymbol: currencySymbol)
            }
            .bind(to: currentBidPriceLabel.rx.text)
            .disposed(by: rx.disposeBag)
        
        for subview in [artworkImageView, artistNameLabel, artworkTitleLabel, currentBidPriceLabel] {
            self.addSubview(subview)
        }
        
        self.constrainHeight("60")
        
        artworkImageView.alignTop("0", leading: "0", bottom: "0", trailing: nil, to: self)
        artworkImageView.constrainWidth("84")
        artworkImageView.constrainHeight("60")

        artistNameLabel.alignAttribute(.top, to: .top, of: self, predicate: "0")
        artistNameLabel.constrainHeight("16")
        artworkTitleLabel.alignAttribute(.top, to: .bottom, of: artistNameLabel, predicate: "8")
        artworkTitleLabel.constrainHeight("16")
        currentBidPriceLabel.alignAttribute(.top, to: .bottom, of: artworkTitleLabel, predicate: "4")
        currentBidPriceLabel.constrainHeight("16")
        
        UIView.alignAttribute(.leading, ofViews: [artistNameLabel, artworkTitleLabel, currentBidPriceLabel], to:.trailing, ofViews: [artworkImageView, artworkImageView, artworkImageView], predicate: "20")
        UIView.alignAttribute(.trailing, ofViews: [artistNameLabel, artworkTitleLabel, currentBidPriceLabel], to:.trailing, ofViews: [self, self, self], predicate: "0")

    }

}
