//
//  GameViewController.swift
//  CookieCrunch
//
//  Created by Olivia Taylor on 11/7/17.
//  Copyright © 2017 oliviataylor. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

class GameViewController: UIViewController {

    var scene: GameScene!
    var level: Level!
    
    var movesLeft = 0
    var score = 0
    var currentLevelNum = 0
    
    @IBOutlet weak var targetLabel: UILabel!
    @IBOutlet weak var movesLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var gameOverPanel: UIImageView!
    @IBOutlet weak var shuffleButton: UIButton!
    
    var tapGestureRecognizer: UITapGestureRecognizer!
    
    lazy var backgroundMusic: AVAudioPlayer? = {
        guard let url = Bundle.main.url(forResource: "Mining by Moonlight", withExtension: "mp3") else {
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            return player
        } catch {
            return nil
        }
    }()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .portraitUpsideDown]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLevel(levelNum: currentLevelNum)
        backgroundMusic?.play()
    }
    
    func setupLevel(levelNum: Int) {
        let skView = view as! SKView
        skView.isMultipleTouchEnabled = false
        
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        
        level = Level(filename: "Level_\(levelNum)")
        scene.level = level
        scene.addTiles()
        scene.swipeHandler = handleSwipe
        
        gameOverPanel.isHidden = true
        
        skView.presentScene(scene)
        beginGame()
    }
    
    func beginGame() {
        movesLeft = level.maximumMoves
        score = 0
        updateLabels()
        level.resetComboMultiplier()
        scene.animateBeginGame {
            self.shuffleButton.isHidden = false
        }
        shuffle()
    }
    
    func shuffle() {
        scene.removeAllCookieSprites()
        let newCookies = level.shuffle()
        scene.addSprites(for: newCookies)
    }
    
    func handleSwipe(swap: Swap) {
        view.isUserInteractionEnabled = false
        if level.isPossibleSwap(swap) {
            level.performSwap(swap: swap)
            if swap.cookieA.cookieType == .bomb || swap.cookieB.cookieType == .bomb {
                var endCookie = swap.cookieA
                if swap.cookieA.cookieType != .bomb {
                    endCookie = swap.cookieB
                }
                scene.animate(swap) {
                    self.handleBombs(column: endCookie.column, row: endCookie.row, cookie: endCookie)
                    self.handleMatches(isBomb: false)
                }
            } else {
                scene.animate(swap) {
                    self.handleMatches(isBomb: false)
                }
            }
        } else {
            scene.animateInvalidSwap(swap) {
                self.view.isUserInteractionEnabled = true
            }
        }
    }
    
    func handleBombs(column: Int, row: Int, cookie: Cookie) {
        level.bombCount = 1
        let count = level.handleBombs(column: column, row: row)
        if count - 2 > 0 {
            self.score += count * 9 * 60
        }
        scene.animateCookieScore(for: cookie, score: (count * 9 * 60))
        self.updateLabels()
        let columns = self.level.fillHoles()
        self.scene.animateFallingCookies(columns: columns) {
            let columns = self.level.topUpCookies()
            self.scene.animateNewCookies(columns) {
                self.handleMatches(isBomb: true)
            }
        }
    }
    
    func handleMatches(isBomb: Bool) {
        let chains = level.removeMatches()
        if chains.count == 0 {
            _ = level.detectPossibleSwaps()
            if !isBomb {
                beginNextTurn()
            }
            return
        }
        scene.animateMatchedCookies(for: chains) {
            for chain in chains {
                self.score += chain.score
            }
            self.updateLabels()
            self.scene.addSprites(for: Set(matches))
            let columns = self.level.fillHoles()
            self.scene.animateFallingCookies(columns: columns) {
                let columns = self.level.topUpCookies()
                self.scene.animateNewCookies(columns) {
                    self.handleMatches(isBomb: false)
                }
            }
        }
    }
    
    func beginNextTurn() {
        let count = level.detectPossibleSwaps()
        view.isUserInteractionEnabled = true
        decrementMoves()
        level.resetComboMultiplier()
        if count == 0 {
            self.shuffle()
        }
    }
    
    func updateLabels() {
        targetLabel.text = String(format: "%ld", level.targetScore)
        movesLabel.text = String(format: "%ld", movesLeft)
        scoreLabel.text = String(format: "%ld", score)
    }
    
    func decrementMoves() {
        movesLeft -= 1
        updateLabels()
        if score >= level.targetScore {
            gameOverPanel.image = UIImage(named: "LevelComplete")
            currentLevelNum = currentLevelNum < NumLevels ? currentLevelNum + 1 : 0
            showGameOver()
        } else if movesLeft == 0 {
            gameOverPanel.image = UIImage(named: "GameOver")
            showGameOver()
        }
    }
    
    func showGameOver() {
        gameOverPanel.isHidden = false
        scene.isUserInteractionEnabled = false
        shuffleButton.isHidden = true
        
        scene.animateGameOver() {
            self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.hideGameOver))
            self.view.addGestureRecognizer(self.tapGestureRecognizer)
        }
    }
    
    @objc func hideGameOver() {
        view.removeGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer = nil
        
        gameOverPanel.isHidden = true
        scene.isUserInteractionEnabled = true
        
        setupLevel(levelNum: currentLevelNum)
    }
    
    @IBAction func shuffleButtonTapped(_: AnyObject) {
        shuffle()
        decrementMoves()
    }
    
}












