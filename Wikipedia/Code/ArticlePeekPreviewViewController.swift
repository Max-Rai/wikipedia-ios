import UIKit
import WMF

@objc (WMFArticlePeekPreviewViewController)
class ArticlePeekPreviewViewController: UIViewController {
    
    @objc let articleURL: URL
    fileprivate let dataStore: MWKDataStore
    fileprivate var theme: Theme

    @IBOutlet weak var leadImageView: UIImageView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var textLabel: UILabel!
    
    @objc weak var delegate: WMFArticlePreviewingActionsDelegate?
    
    @objc required init(articleURL: URL, dataStore: MWKDataStore, theme: Theme) {
        self.articleURL = articleURL
        self.dataStore = dataStore
        self.theme = theme
        super.init(nibName: "ArticlePeekPreviewViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    func fetchArticle() {
        if let article = dataStore.fetchArticle(with: articleURL) {
            updateView(with: article)
        }
    }
    
    func updateView(with article: WMFArticle) {
        
        if let imageURL = article.imageURL(forWidth: traitCollection.wmf_leadImageWidth) {
            self.leadImageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in
                self.leadImageView.isHidden = true
            }, success: {
                //handle success
            })
        } else {
            leadImageView.isHidden = true

        }
        
        self.titleLabel.text = article.displayTitle
        self.descriptionLabel.text = article.capitalizedWikidataDescription
        self.textLabel.text = article.snippet
    }
    
    override func viewDidLoad() {
        fetchArticle()
        updateFonts()
        apply(theme: theme)
    }
    
    func updateFonts() {
        titleLabel.setFont(with: .georgia, style: .title1, traitCollection: traitCollection)
        descriptionLabel.setFont(with: .system, style: .subheadline, traitCollection: traitCollection)
        textLabel.setFont(with: .system, style: .body, traitCollection: traitCollection)
        textLabel.lineBreakMode = .byTruncatingTail
        
        if #available(iOS 11.0, *) {
            leadImageView.accessibilityIgnoresInvertColors = true
        }
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        //TODO: localize
        let readNow = UIPreviewAction(title: "Read now", style: .default) { (_, _) in
            let articleViewController = WMFArticleViewController(articleURL: self.articleURL, dataStore: self.dataStore, theme: self.theme)
            self.delegate?.readMoreArticlePreviewActionSelected(withArticleController: articleViewController)
        }
        
        let savedPages = dataStore.savedPageList
        let isSaved = savedPages.isSaved(articleURL)
        let saveTitle = isSaved ? "Remove from saved" : CommonStrings.saveTitle
        let save = UIPreviewAction(title: saveTitle, style: .default) { (_, _) in
            if isSaved {
                savedPages.removeEntry(with: self.articleURL)
            } else {
                savedPages.addSavedPage(with: self.articleURL)
            }
        }
        
        //add share
        
        return [readNow, save]
    }
}

extension ArticlePeekPreviewViewController: AnalyticsContextProviding, AnalyticsViewNameProviding {
    //change
    var analyticsName: String {
        return "ArticleList"
    }
    
    var analyticsContext: String {
        return analyticsName
    }
}

extension ArticlePeekPreviewViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        titleLabel.textColor = theme.colors.primaryText
        descriptionLabel.textColor = theme.colors.secondaryText
        headerView.backgroundColor = theme.colors.midBackground
        textLabel.textColor = theme.colors.primaryText
    }
}
