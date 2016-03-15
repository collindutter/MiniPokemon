//<>//
//Collin Dutter
//Brandon Kelley
//Allison Lee

/* Hi there— this is Allison!
 > Transformation: Our Pikachu evolves from a Pikachu to a Raichu!
 > Two different animated characters: All the pokemon, the player sprite
 > Animated components: Lots of the backgrounds, sequences, sprites themselves, attacks, etc. (there are 
 a lot of classes so it'll probably bebetter not to name it all
 > Coherent background: The forest and grass are drawn with a loop. The bubbles at the beginning are also 
 drawn with a loop. The evolution sequence also uses loops.
 > Beginning: lost in the forest
 Middle: battle
 End: get out!
 > Interesting: Hopefully, it was fun to play?
 
 We all sort of edited each other's code, but for the most part the work is split up like this:
 > Brandon did the overworld sprites and walking logic (like keypressed), as well as the steps counting to the encounter.
 > Collin did the battle logic (making the moves work and displaying attack names on the
 screen, number values for hit points etc (and there sure was a lot and lot of code for this)
 > I dealt with all the visual components and animations of the sprites (attack moves when the attacks are chosen
 and title and evolution sequences since drawing is fun for me 
 */

Screen currentScreen;
boolean playopening = false;
boolean openingdone = false;
void setup() {
  size(600, 400);
  currentScreen = new OpeningScreen();
}

void draw() {
  currentScreen.drawScreen();
}

abstract class Screen {  
  //declare universal game font
  private PFont gameFont;

  public Screen() {
    //create and load font into game
    gameFont = createFont("res/sapphirefont.ttf", 32);
    textFont(gameFont);
  }
  public abstract void drawScreen();
}

class CreditsScreen extends Screen {
  public void drawScreen() {
    background(0);
    textAlign(CENTER);
    textSize(32);
    text("Thank you for playing!", width/2, height/2-64);
    text("An interactive story by: ", width/2, height/2);
    text("Collin Dutter ", width/2, height/2+32);
    text("Brandon Kelley", width/2, height/2+64);
    text("Allison Lee", width/2, height/2+96);
    textAlign(LEFT);
  }
}


void keyPressed() {
  //if current screen is the titlescreen, change to world screen when pressing enter
  if (currentScreen instanceof OpeningScreen) {
    if (keyCode == ENTER) {
      playopening = true;
      if (playopening && openingdone) {
        currentScreen = new WorldScreen(true);
      }
    } else if (keyCode == TAB)
      currentScreen = new WorldScreen(true);
  }
  if (currentScreen instanceof BattleScreen) {
    final BattleScreen bs = ((BattleScreen)currentScreen);

    if (keyCode == ENTER) {

      //if current menu is an infobar
      if (bs.currentMenu instanceof InfoBar) {
        //if next infobar is nothing, skip it, and switch to decision bar
        if (bs.infoBarQueue.get(bs.menuIndex+1) == null) {
          bs.menuIndex+=2;
          bs.currentMenu = new DecisionBar(bs.ash.moves, bs.ash.pikachu.name);
          //otherwise go to the next infobar
        } else {
          if (bs.infoBarQueue.get(bs.menuIndex).message == "")
            return;
          bs.menuIndex++;
          bs.currentMenu = bs.infoBarQueue.get(bs.menuIndex);
          // bs.currentMenu.doAction();
        }
      }
      //if current menu is a decision bar, display appropriate message, or change it to attack bar 
      else if (bs.currentMenu instanceof DecisionBar) {
        int row = ((DecisionBar)bs.currentMenu).selectorRow;
        int col = ((DecisionBar)bs.currentMenu).selectorCol;

        if (row == 0 && col == 0) {
          bs.currentMenu = new AttackBar(bs.ash.pikachu.attacks);
          return;
        } else if (row == 0 && col == 1) 
          bs.infoBarQueue.add(new InfoBar("Items not allowed!"));
        else if (row == 1 && col == 1) 
          bs.infoBarQueue.add(new InfoBar("You cannot run!"));
        else if (row == 1 && col == 0) 
          bs.infoBarQueue.add(new InfoBar("You have no other Pokemon!"));
        bs.infoBarQueue.add(null);
        bs.currentMenu = bs.infoBarQueue.get(bs.menuIndex);
      } 
      //if current menu is an attack bar, deal appropriate damage to enemy, and recieve damage
      else if (bs.currentMenu instanceof AttackBar) {
        //player attacking
        final Pokemon.Attack attack = bs.ash.pikachu.attacks[((AttackBar)bs.currentMenu).selectorRow][((AttackBar)bs.currentMenu).selectorCol];
        if (attack.pp > 0) {
          bs.infoBarQueue.add(new InfoBar("Pikachu used " + attack.name + "!") {
            public void doAction() {
              //bs.enemies[bs.enemyIndex].health-=attack.damage;
              attack.pp--;
              bs.drawAttack = true;
              bs.playerAttackStart = millis();
              bs.playerAttackToDraw = attack;
              bs.ash.pikachu.xp+=5;
            }
          }
          );
          bs.infoBarQueue.add(new InfoBar("It was super effective!"));
        } else {
          bs.infoBarQueue.add(new InfoBar("Out of PP!"));
        }
        bs.enemies[bs.enemyIndex].health-=attack.damage;

        if (bs.ash.pikachu.xp >= bs.ash.pikachu.maxXP) {
          bs.ash.pikachu.xp = 0; 
          bs.ash.pikachu.level++;
          bs.ash.pikachu.maxXP+=25;
          bs.ash.pikachu.health = bs.ash.pikachu.MAX_HEALTH;
          bs.infoBarQueue.add(new InfoBar(bs.ash.pikachu.name + " has leveled up!"));
        }
        //enemy attacking
        final Pokemon.Attack enemyAttack = bs.enemies[bs.enemyIndex].attacks[(int)random(0, 2)] [(int)random(0, 2)];
        if (bs.enemies[bs.enemyIndex].health > 0) {
          bs.infoBarQueue.add(new InfoBar(bs.enemies[bs.enemyIndex].name + " used " + enemyAttack.name + "!") {
            public void doAction() {
              bs.ash.pikachu.health -= enemyAttack.damage;
              enemyAttack.pp--;
              bs.drawEnemyAttack = true;
              bs.enemyAttackStart = millis();
              bs.enemyAttackToDraw = enemyAttack;
            }
          }
          );
        }
        //if the enemy is dead 
        else if (bs.enemies[bs.enemyIndex].health <= 0) {
          //create a message indicating it has died--potentially end game
          if (bs.enemyIndex == 0)
            bs.infoBarQueue.add(new InfoBar(bs.enemies[bs.enemyIndex].name + " has fainted!") {
              public void doAction() {
                bs.drawEnemyExit = true;
                frameCount = 0;
              }
            }
          );
          else if (bs.enemyIndex == 1) {
            bs.infoBarQueue.add(new InfoBar(bs.enemies[bs.enemyIndex].name + " has fainted!")
            {
              public void doAction() {
                bs.drawEnemyExit = true;
                frameCount = 0;
              }
            }
            );
            bs.infoBarQueue.add(new InfoBar(" ") {
              public void doAction() {
                bs.fadingOut = true;
              }
            }
            );
          }

          bs.infoBarQueue.add(new InfoBar("Wild " + bs.enemies[bs.enemyIndex+(bs.enemyIndex < 1? 1 :0)].name + " has appeared!") {
            public void doAction() {
              //change out the pokemon
              if (bs.enemyIndex < 1)
                bs.enemyIndex++;
              bs.drawEnemyEntrance = true;
              frameCount = 0;
            }
          }
          );
        } 
        bs.infoBarQueue.add(null);
        bs.currentMenu = bs.infoBarQueue.get(bs.menuIndex);
      }
      //do the current info screena action      
      bs.currentMenu.doAction();
    }
    //handles menu navigation on attack and decision bar menus
    if (bs.currentMenu instanceof AttackBar) {
      AttackBar ab = ((AttackBar)bs.currentMenu);
      if (keyCode == LEFT && ab.selectorCol > 0) 
        ab.selectorCol--;
      if (keyCode == RIGHT && ab.selectorCol < 1 ) 
        ab.selectorCol++;
      if (keyCode == UP && ab.selectorRow > 0 ) 
        ab.selectorRow--;
      if (keyCode == DOWN && ab.selectorRow < 1) 
        ab.selectorRow++;
    } else if (bs.currentMenu instanceof DecisionBar) {
      DecisionBar db = ((DecisionBar)bs.currentMenu);
      if (keyCode == LEFT && db.selectorCol > 0) 
        db.selectorCol--;
      if (keyCode == RIGHT && db.selectorCol < 1 ) 
        db.selectorCol++;
      if (keyCode == UP && db.selectorRow > 0 ) 
        db.selectorRow--;
      if (keyCode == DOWN && db.selectorRow < 1) 
        db.selectorRow++;
    }
  }
  //allow key press for worldscreen
  if (currentScreen instanceof WorldScreen)
    worldKeyPress = true;
}

class BattleScreen extends Screen {
  public boolean drawIntroText;
  public boolean drawAttack, drawEnemyAttack;
  public boolean drawPlayerEntrance = true, drawEnemyEntrance = true, drawEnemyExit;
  public float playerAttackStart, enemyAttackStart;
  public Pokemon.Attack enemyAttackToDraw, playerAttackToDraw;
  private Pokemon[] enemies;
  public Player ash;
  private PImage playerHealthUI, enemyHealthUI;
  private PImage whiteScreen;
  public float opacity, opacity2 = 255;
  public boolean fadingOut;
  private UIComponent currentMenu;
  public int menuIndex = 0;
  public ArrayList<InfoBar> infoBarQueue;
  public int enemyIndex = 0;

  public BattleScreen() {
    //bottomBarUI = loadImage("bottombar.png");
    playerHealthUI = loadImage("res/UI/playerhealth.png");
    enemyHealthUI = loadImage("res/UI/enemyhealth.png");
    whiteScreen = loadImage("res/op/12_white.png");
    ash = new Player();
    drawIntroText = true;
    enemies = new Pokemon[2];
    enemies[enemyIndex] = new Squirtle();
    enemies[1] = new Bulbasaur();
    infoBarQueue = new ArrayList<InfoBar>(50);

    infoBarQueue.add(new InfoBar("Wild " + enemies[enemyIndex].name + " appeared!") {
      void doAction() {
        drawEnemyEntrance = true;
      }
    }
    );
    infoBarQueue.add(null);
    currentMenu = infoBarQueue.get(0);
    frameCount = 0;
  }

  public void drawScreen() {
    frameRate(25);
    drawBackground();
    ash.pikachu.drawPokemon();
    enemies[enemyIndex].drawPokemon();
    drawHealthIndicators();
    //draws pokemon attacks
    if (drawAttack) {
      ash.pikachu.pikachubounce = true;
      if (ash.pikachu.drawAttack(playerAttackToDraw, playerAttackStart) == false) {
        drawAttack = false;
        ash.pikachu.pikachubounce = false;
      }
    }
    if (drawEnemyAttack) {
      enemies[enemyIndex].enemybounce = true;
      if (enemies[enemyIndex].drawAttack(enemyAttackToDraw, enemyAttackStart) == false) {
        drawEnemyAttack = false;
        enemies[enemyIndex].enemybounce = false;
      }
    }
    currentMenu.drawUIComponent();

    if (drawPlayerEntrance) {
      ash.pikachu.x+=ash.dx*.1;
      if (frameCount >= 20)
        drawPlayerEntrance = false;
    }
    if (drawEnemyEntrance) {
      enemies[enemyIndex].x-=enemies[enemyIndex].dx*.1;
      if (frameCount >= 21)
        drawEnemyEntrance = false;
    } else if (drawEnemyExit) {
      enemies[enemyIndex].x+=enemies[enemyIndex].dx*.1;
      if (frameCount >=21)
        drawEnemyExit = false;
    }
    if (fadingOut && opacity <= 270) {
      tint(255, opacity);
      image(whiteScreen, 0, 0);
      opacity+=20;
    } else if (opacity >=270) {
      image(whiteScreen, 0, 0);
      currentScreen = new WorldScreen(false);
    }
    tint(255, 255);
  }
  //draws health indicators
  private void drawHealthIndicators() {
    //health bars
    fill(243, 212, 65);
    noStroke();
    rect(437, 225, ash.pikachu.health*111/ash.pikachu.MAX_HEALTH, 15);
    rect(134, 70, enemies[enemyIndex].health*111/enemies[enemyIndex].MAX_HEALTH, 15);
    //xp bar
    fill(18, 208, 241);
    rect(396, 262, ash.pikachu.xp*165/ash.pikachu.maxXP, 12);

    image(playerHealthUI, 0, 0);
    image(enemyHealthUI, 0, 0);


    //names and levels
    textSize(33);
    fill(88, 79, 57);
    text(enemies[enemyIndex].name, 48, 60);
    text(ash.pikachu.name, 355, 220);
    text(ash.pikachu.level, 530, height/2+17);
    text(enemies[enemyIndex].level, 230, height/11+23);
  }

  //draws greenish background
  private void drawBackground() {
    background(#D4F2D0);
    strokeWeight(4);
    stroke(#D9F7D5);
    for (int i = 0; i < 25; i++)
      line(0, i*height/25, width, i*height/25);
    strokeWeight(1);
    noStroke();
    fill(#A3F273);
    ellipse(width*3/4-10, height*3/8+10, width/2, height/5);
    ellipse(width/4+10, height*6/8-10, width/2, height/5);
    fill(#79D081);
    ellipse(width*3/4-10, height*3/8+10, width/2-20, height/5-20);
    ellipse(width/4+10, height*6/8-10, width/2-20, height/5-20);
    stroke(0);
  }
}

public class UIComponent {
  public PImage sprite;
  public UIComponent(String fileName) {
    sprite = loadImage(fileName);
  }  
  public void drawUIComponent() {
    image(sprite, 0, 0);
  }
  void doAction() {
  }
}

public class InfoBar extends UIComponent {
  String message;
  public InfoBar(String message) {
    super("res/UI/infobar.png");
    this.message = message;
  } 
  public void drawUIComponent() {
    if (message == "")
      return;
    super.drawUIComponent();
    fill(255);
    textSize(33);
    text(message, 40, 330);
  }
  public void doAction() {
  }
}

public class AttackBar extends UIComponent {
  public int selectorCol, selectorRow;

  public Pokemon.Attack[][] attacks;
  public AttackBar(Pokemon.Attack[][] attacks) {
    super("res/UI/attackbar.png");
    this.attacks = attacks;
  }
  public void drawUIComponent() {
    super.drawUIComponent();
    fill(0);
    textSize(33);
    for (int row = 0; row < 2; row++) 
      for (int col = 0; col < 2; col++) 
        text(attacks[row][col].name, 30 + col*210, 330 + row*40);
    noFill();
    strokeWeight(2);
    stroke(255, 0, 0);
    rect(30 + selectorCol*210, 300 + selectorRow*40, textWidth(attacks[selectorRow][selectorCol].name), 30);
    noFill();
    text("PP", 460, 335);
    textSize(32);
    text(attacks[selectorRow][selectorCol].pp + "/" + attacks[selectorRow][selectorCol].maxPP, 500, 335);
    textSize(33);
    text("Normal", 460, 375);
  }
  public void doAction() {
  }
}

public class DecisionBar extends UIComponent {
  public int selectorCol, selectorRow;
  public String[][] moves;
  public String name;
  public DecisionBar(String[][] moves, String name) {
    super("res/UI/decisionbar.png");
    this.moves = moves;
    this.name = name;
  }
  void drawUIComponent() {
    super.drawUIComponent();
    fill(0);
    textSize(35);
    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 2; col++) { 
        text(moves[row][col], 375 + col*130, 330 + row*40);
      }
    }
    fill(255);
    text("What should \n"+ name + " do?", 40, 330);
    noFill();
    strokeWeight(2);
    stroke(255, 0, 0);
    rect(375 + selectorCol * 130, 300 + selectorRow*40, textWidth(moves[selectorRow][selectorCol]), 30);
  }
}



class Player {
  private PImage sprite;
  public float x, y;
  public float dx;
  public Pikachu pikachu;
  //list of available moves for player
  public final String[][] moves = {
    {
      "FIGHT", "ITEM"
    }
    , 
    {
      "POKeMON", "RUN"
    }
  };

  public Player() {
    sprite = loadImage("res/ash/ash.png");
    x = -50;
    y = 150;
    dx = 100;
    pikachu = new Pikachu();
  }

  public void drawPlayer() {
    image(sprite, x, y, 16*5, 32*7);
  }
}

abstract class Pokemon {
  public boolean enemybounce;
  public int health;
  public int MAX_HEALTH;
  protected PImage sprite;
  protected float x, y;
  protected float dx, dy;
  public String name;
  public Attack[][] attacks;
  public int level;

  public Pokemon() {
    dx = 100;
  }

  public class Attack {
    public String name;
    public int damage;
    public int maxPP;
    public int pp;
    public Attack(String name, int damage, int maxPP) {
      this.name = name;
      this.damage = damage;
      this.maxPP = maxPP;
      pp = maxPP;
    }
  }

  public boolean drawAttack(Attack at, float start) {
    return false;
  }
  public void drawPokemon() {
    //image(sprite, x, y, 16*5, 32*5);
  }
}

class Pikachu extends Pokemon {
  public boolean pikachubounce;
  public int maxXP;
  public int xp;
  private int radius;
  private int delta = 1;
  private float lineX = 230;
  private float lineY = 210;
  private float dx1 = 30;
  private float dy1 = -1.5;
  private float dx2 = -0.75;
  private float dy2 = -15;
  private float theta;
  private float electroX, electroY;
  private int attackindex = 14;
  private int idleindex = 34;
  private int thunderboltindex = 8;
  private int growlindex = 5;
  private int thundershockindex = 6;
  private int electroballindex = 10;

  private PImage[] pikachuidle = new PImage[idleindex];
  private PImage[] pikachuattack = new PImage[attackindex];
  private PImage[] thunderbolt = new PImage[thunderboltindex];
  private PImage[] thundershock = new PImage[thundershockindex];
  private PImage[] growl = new PImage[growlindex];
  private PImage[] electroball = new PImage[electroballindex];
  public Pikachu() {
    for (int i = 0; i<pikachuidle.length; i++) {
      pikachuidle[i] = loadImage("res/pokemon/pikachu/pikachuidle" + i + ".png");
    }
    for (int j = 0; j<pikachuattack.length; j++) {
      pikachuattack[j] = loadImage("res/pokemon/pikachu/pikachu" + j + ".png");
    }
    for (int a = 0; a<thunderbolt.length; a++) {
      thunderbolt[a] = loadImage("res/attack/thunderbolt/thunderbolt_" + a + ".png");
    }
    for (int b = 0; b<growl.length; b++) {
      growl[b] = loadImage("res/attack/growl/growl_" + b + ".png");
    }    
    for (int c = 0; c<thundershock.length; c++) {
      thundershock[c] = loadImage("res/attack/thundershock/thundershock_" + c + ".png");
    }
    for (int d = 0; d<electroball.length; d++) {
      electroball[d] = loadImage("res/attack/electroball/electroball_" + d + ".png");
    }

    x = -110;
    y = 160;
    dx = 100;
    level = 4;
    name = new String("PIKACHU");
    maxXP = 100;
    xp = 80;
    MAX_HEALTH = 100;
    health = MAX_HEALTH;
    attacks = new Attack[][] {
      {
        new Attack("ELECTRO BALL", 15, 25), new Attack("THUNDERBOLT", 15, 25)
        }
        , 
      {
        new Attack("THUNDER SHOCK", 15, 25), new Attack("QUICK ATTACK", 15, 25)
        }
      };
    }
    public void drawPokemon() {
      if (pikachubounce) {
        bounce();
      } else {
        idle();
      }
    }
  public void idle() {
    idleindex = (idleindex < 34 ? idleindex+1 : idleindex)%pikachuidle.length;
    image(pikachuidle[idleindex], x, y);
  }

  public void bounce() {
    attackindex = (attackindex < 14 ? attackindex+1 : attackindex)%pikachuattack.length;
    image(pikachuattack[attackindex], x, y);
  }
  public boolean drawAttack(Attack at, float start) {

    fill(color(random(0, 255), random(0, 255), random(0, 255)));
    if (at.name == "THUNDERBOLT") {
      frameRate(30);
      if (millis () - start < 500) {
        thunderboltindex = (thunderboltindex < 8 ? thunderboltindex+1 : thunderboltindex)%thunderbolt.length;
        image(thunderbolt[thunderboltindex], 350, 20);
        return true;
      }
    } else if (at.name == "QUICK ATTACK") {
      if (millis () - start < 500) {
        growlindex = (growlindex < 5 ? growlindex+1 : growlindex)%growl.length;
        imageMode(CENTER);
        image(growl[growlindex], 430, 120);
        imageMode(CORNER);
        return true;
      }
    } else if (at.name == "THUNDER SHOCK") {
      if (millis () - start < 500) {
        thundershockindex = (thundershockindex < 6 ? thundershockindex+1 : thundershockindex)%thundershock.length;
        imageMode(CENTER);
        image(thundershock[thundershockindex], 430, 120);
        imageMode(CORNER);
        return true;
      }
    } else if (at.name == "ELECTRO BALL") {
      if (millis() - start < 1500) {
        if (millis () - start < 400) {
          electroX = 230;
          electroY = 210;
        } else if (millis() - start < 1000) {
          //this mumbo jumbo makes figures out velocities to make it get to destination in exactly 600 ms.
          electroX += (430-230)/(frameRate*3/5.0);
          electroY += (100-210)/(frameRate*3/5.0);
        } else {
          electroX = 430;
          electroY = 100;
        }
        electroballindex = (electroballindex < 10 ? electroballindex+1 : electroballindex)%electroball.length;
        imageMode(CENTER);
        image(electroball[electroballindex], electroX, electroY);
        imageMode(CORNER);
        return true;
      }
    }

    return false;
  }
}

class Bulbasaur extends Pokemon {
  private float theta;
  private float leafX, leafY;
  private float radius;
  private int attackindex = 20;
  private int idleindex = 20;
  private int seedindex = 14;
  private int growlindex = 5;
  private int leafindex = 7;
  private int vineindex = 19;
  private PImage[] bulbasauridle = new PImage[idleindex];
  private PImage[] bulbasaurattack = new PImage[attackindex];
  private PImage[] seed = new PImage[seedindex];
  private PImage[] growl = new PImage[growlindex];
  private PImage[] leaf = new PImage[leafindex];
  private PImage[] vine = new PImage[vineindex];


  public Bulbasaur() {
    name = new String("BULBASAUR");
    MAX_HEALTH = 90;
    health = MAX_HEALTH;
    level = 5;
    x = 605;
    y = 70;
    attacks = new Attack[][] {
      {//tackle vine whip leech seed razor leaf
        new Attack("TACKLE", 15, 25), new Attack("VINE WHIP", 15, 25)
        }
        , 
      {
        new Attack("LEECH SEED", 15, 25), new Attack("RAZOR LEAF", 15, 25)
        }
      };
      for (int i = 0; i<bulbasauridle.length; i++) {
        bulbasauridle[i] = loadImage("res/pokemon/bulbasaur/bulbasauridle" + i + ".png");
      }
    for (int j = 0; j<bulbasaurattack.length; j++) {
      bulbasaurattack[j] = loadImage("res/pokemon/bulbasaur/bulbasaur" + j + ".png");
    }
    for (int a = 0; a < seed.length; a++) {
      seed[a] = loadImage("res/attack/seed/seed_" + a + ".png");
    }
    for (int b = 0; b < growl.length; b++) {
      growl[b] = loadImage("res/attack/growl/growl_" + b + ".png");
    }
    for (int c = 0; c < leaf.length; c++) {
      leaf[c] = loadImage("res/attack/leaf/leaf_" + c + ".png");
    }
    for (int d = 0; d < vine.length; d++) {
      vine[d] = loadImage("res/attack/vine/vine_" + d + ".png");
    }
  }

  public void bounce() {
    attackindex = (attackindex < 20 ? attackindex+1 : attackindex)%bulbasaurattack.length;
    image(bulbasaurattack[attackindex], x, y);
  }
  public void idle() {
    idleindex = (idleindex < 20 ? idleindex+1 : idleindex)%bulbasauridle.length;
    image(bulbasauridle[idleindex], x, y);
  }

  public void drawPokemon() {
    if (enemybounce) {
      bounce();
    } else {
      idle();
    }
  }

  public boolean drawAttack(Attack at, float start) {
    fill(color(random(0, 255), random(0, 255), random(0, 255)));
    if (at.name == "TACKLE") {
      if (millis () - start < 500) {
        growlindex = (growlindex < 5 ? growlindex+1 : growlindex)%growl.length;
        imageMode(CENTER);
        image(growl[growlindex], 180, 230);
        imageMode(CORNER);
        return true;
      }
    } else if (at.name == "VINE WHIP") {
      if (millis () - start < 1300) {
        vineindex = (vineindex < 19 ? vineindex+1 : vineindex)%vine.length;
        image(vine[vineindex], 60, 100);
        return true;
      }
    } else if (at.name == "LEECH SEED") {
      if (millis () - start < 1000) {
        seedindex = (seedindex < 14 ? seedindex+1 : seedindex)%seed.length;
        image(seed[seedindex], 50, 200);
        image(seed[seedindex], 130, 190);
        return true;
      }
    } else if (at.name == "RAZOR LEAF") {
      if (millis() - start < 900) {
        if (millis () - start < 300) {
          leafX = 430;
          leafY = 100;
        } else if (millis() - start < 900) {
          //this mumbo jumbo makes figures out velocities to make it get to destination in exactly 600 ms.
          leafX += (230-430)/(frameRate*3/5.0);
          leafY += (210-100)/(frameRate*3/5.0);
        } else {
          leafX = 230;
          leafY = 210;
        }
        leafindex = (leafindex < 7 ? leafindex+1 : leafindex)%leaf.length;
        imageMode(CENTER);
        image(leaf[leafindex], leafX, leafY);
        imageMode(CORNER);
        return true;
      }
    }

    return false;
  }
}
class Squirtle extends Pokemon {
  private float radius;
  private float theta;
  private int waterX, waterY;
  private int attackindex = 22;
  private int idleindex = 32;
  private int biteindex = 15;
  private int growlindex = 5;
  private int waterindex = 5;
  private int bubbleindex = 10;
  private PImage[] squirtleidle = new PImage[idleindex];
  private PImage[] squirtleattack = new PImage[attackindex];
  private PImage[] bite = new PImage[biteindex];
  private PImage[] growl = new PImage[growlindex];
  private PImage[] water = new PImage[waterindex];
  private PImage[] bubble = new PImage[bubbleindex];  

  public Squirtle() {
    name = new String("SQUIRTLE");
    MAX_HEALTH = 90;
    level = 4;
    health = MAX_HEALTH;
    x = 600;
    y = 50;
    attacks = new Attack[][] {
      {//tackle bite
        new Attack("TACKLE", 15, 25), new Attack("BITE", 15, 25)
        }
        , 
      {
        new Attack("WATER GUN", 15, 25), new Attack("BUBBLE", 15, 25)
        }
      };

      for (int i = 0; i<squirtleidle.length; i++) {
        squirtleidle[i] = loadImage("res/pokemon/squirtle/squirtleidle" + i + ".png");
      }
    for (int j = 0; j<squirtleattack.length; j++) {
      squirtleattack[j] = loadImage("res/pokemon/squirtle/squirtle" + j + ".png");
    }
    for (int a = 0; a < bite.length; a++) {
      bite[a] = loadImage("res/attack/bite/bite_" + a + ".png");
    }
    for (int b = 0; b < growl.length; b++) {
      growl[b] = loadImage("res/attack/growl/growl_" + b + ".png");
    }
    for (int c = 0; c < water.length; c++) {
      water[c] = loadImage("res/attack/water/water_" + c + ".png");
    }
    for (int d = 0; d < bubble.length; d++) {
     bubble[d] = loadImage("res/attack/bubble/bubble_" + d + ".png");
     }
  }

  public void idle() {
    idleindex = (idleindex < 32 ? idleindex+1 : idleindex)%squirtleidle.length;
    image(squirtleidle[idleindex], x, y);
  }
  public void bounce() {
    attackindex = (attackindex<22?attackindex+1 : attackindex)%squirtleattack.length;
    image(squirtleattack[attackindex], x, y);
  }
  public void drawPokemon() {
    if (enemybounce) {
      bounce();
    } else {
      idle();
    }
  }

  public boolean drawAttack(Attack at, float start) {
    fill(color(random(0, 255), random(0, 255), random(0, 255)));
    if (at.name == "TACKLE") {
      if (millis () - start < 500) {
        growlindex = (growlindex < 5 ? growlindex+1 : growlindex)%growl.length;
        imageMode(CENTER);
        image(growl[growlindex], 180, 230);
        imageMode(CORNER);
        return true;
      }
    } else if (at.name == "BITE") {
      if (millis () - start < 1000) {
        biteindex = (biteindex < 15 ? biteindex+1 : biteindex)%bite.length;
        imageMode(CENTER);
        image(bite[biteindex], 150, 230);
        imageMode(CORNER);
        return true;
      }
    } else if (at.name == "WATER GUN") {
      if (millis() - start < 900) {
        if (millis () - start < 300) {
          waterX = 430;
          waterY = 100;
        } else if (millis() - start < 900) {
          //this mumbo jumbo makes figures out velocities to make it get to destination in exactly 600 ms.
          waterX += (230-430)/(frameRate*3/5.0);
          waterY += (210-100)/(frameRate*3/5.0);
        } else {
          waterX = 230;
          waterY = 210;
        }
        waterindex = (waterindex < 5 ? waterindex+1 : waterindex)%water.length;
        imageMode(CENTER);
        image(water[waterindex], waterX, waterY);
        imageMode(CORNER);
        return true;
      }
    } else if (at.name == "BUBBLE") {
      if (millis() - start < 900) {
        if (millis () - start < 200) {
          waterX = 430;
          waterY = 100;
        } else if (millis() - start < 900) {
          //this mumbo jumbo makes figures out velocities to make it get to destination in exactly 600 ms.
          waterX += (230-430)/(frameRate*3/5.0);
          waterY += (210-100)/(frameRate*3/5.0);
        } else {
          waterX = 230;
          waterY = 210;
        }
        bubbleindex = (bubbleindex < 10 ? bubbleindex+1 : bubbleindex)%bubble.length;
        imageMode(CENTER);
        image(bubble[bubbleindex], waterX, waterY);
        imageMode(CORNER);
        return true;
      }
    }
    return false;
  }
}


//booleans to check keyPressed()
boolean titleKeyPress = false;
boolean worldKeyPress = false;
boolean worldKeyRelease = false;

class WorldPlayer {
  //image, position and steps to encounter for sprite in the worldscreen
  public PImage sprite;
  public float posX;
  public float posY;


  public WorldPlayer() {
    sprite = loadImage("res/ash/sprite.png");
    posX = width/2 - sprite.width/2 + 7.5;
    posY = height/2 - sprite.height/2;
  }
}

class WorldScreen extends Screen {                     //WorldScreen
  public boolean intro;
  private int pindex = 16;
  private int rindex = 38;
  private int evolvecount = 0;
  private PImage[] pikachuidle = new PImage[pindex];
  private PImage[] godhelpme = new PImage[rindex];
  //creates playa instance of the WorldPlayer variety
  WorldPlayer playa = new WorldPlayer();
  private PImage tree, grass, field, whiteScreen, blackScreen, evolveScreen, glow, sparkle, sparkle2, sparkle3;
  private PImage pikachu, raichu;
  private float opacity = 0;
  private int glowsize = 0;
  private float opacity2 = 255;
  private float opacity3 = 255;
  private ArrayList<InfoBar> messages;
  private int messageIndex;
  private boolean introEvolve, exitEvolve, fadeToCredits;
  private  int stepsTilEncounter;

  private int sparklesn = 10;
  private float [] sparklesx = new float[sparklesn];
  private float [] sparklesy = new float[sparklesn];
  private float [] sparkles2x = new float[sparklesn];
  private float [] sparkles2y = new float[sparklesn];
  private float [] sparkles3x = new float[sparklesn];
  private float [] sparkles3y = new float[sparklesn];
  private float [] sparklesv = new float[sparklesn];

  public WorldScreen(boolean intro) {
    tree = loadImage("res/world/tree.png");
    grass = loadImage("res/world/grass.png");
    field = loadImage("res/world/field.png");
    whiteScreen = loadImage("res/op/12_white.png");
    evolveScreen = loadImage("res/world/evolve.png");
    glow = loadImage("res/world/glow.png");
    sparkle = loadImage("res/world/sparkle.png");
    sparkle2 = loadImage("res/world/sparkle2.png");
    sparkle3 = loadImage("res/world/sparkle3.png");
    blackScreen = createImage(whiteScreen.width, whiteScreen.height, RGB);

    for (int p = 0; p<pikachuidle.length; p++) {
      pikachuidle[p] = loadImage("res/pokemon/pikachu2/pikachu2_" + p + ".png");
    }
    for (int r = 0; r<godhelpme.length; r++) {
      godhelpme[r] = loadImage("res/pokemon/raichu/raichu_" + r + ".png");
    }

    for (int s = 0; s<sparklesn; s++) {
      sparklesx[s]=random(-100, 700);
      sparklesy[s]=random(400, 500);
      sparkles2x[s]=random(-100, 700);
      sparkles2y[s]=random(400, 500);
      sparkles3x[s]=random(-100, 700);
      sparkles3y[s]=random(400, 500);
      sparklesv[s]=random(5, 10);
    }

    whiteScreen.loadPixels();
    tree.loadPixels();
    grass.loadPixels();
    field.loadPixels();
    this.intro = intro;
    messages = new ArrayList<InfoBar>();
    if (intro) {
      messages.add(new InfoBar("Oh no! Where are you?"));
      messages.add(new InfoBar("This definitely isn't Littleroot Town!"));
      messages.add(new InfoBar("You faintly recall Team Rocket having \nsomething to do with this!"));
      messages.add(new InfoBar("There is a note in the grass!"));
      messages.add(new InfoBar("It reads: \"We have kidnapped you,\nremoved all your possessions except\nPikachu, and sealed the exit!..."));
      messages.add(new InfoBar("...You must defeat the pokemon of this\narea to escape!\"\n-Team Rocket"));
      stepsTilEncounter = messages.size() + int(random(1, 3));
    } else {
      messages.add(new InfoBar("A note dropped!"));
      messages.add(new InfoBar("It reads: \"Good work this time Ash, we'll\nget you next time!\n-Team Rocket"));
      messages.add(new InfoBar("Your Pikachu is evolving!"));
      messages.add(new InfoBar(""));
      messages.add(new InfoBar("Your Pikachu evolved into Raichu!"));
      messages.add(new InfoBar("You are now free to leave to the right!"));
      stepsTilEncounter = 10000000;
    }
  }

  public void drawScreen() {

    //draws field
    for (int j = 0; j < height; j += field.width) {
      for (int i = 0; i < width; i += field.height) {
        image(field, i, j);
      }
    }
    //draws trees and grass
    float approxSlopX = width % tree.width;
    float approxSlopY = height % 33;
    for (float j = approxSlopY/2 - 33; j < height; j += 33) {
      for (float i = approxSlopX/2 - tree.width; i < width; i += tree.width) {
        if (i < 3 * tree.width
          || (intro && i > width - 4 * tree.width)
          || j < 2 * tree.height
          || j > height - 4 * 33  ) {
          image(tree, i, j);
        } else if (i > 4 * grass.width
          && i < 13 * grass.width
          && j > 4 * grass.height
          && j < 8 * grass.height) {
          image(grass, i, j);
        }
      }
    }


    if (messageIndex < messages.size()) {
      messages.get(messageIndex).drawUIComponent();
    }

    if (!(fadeToCredits || (!intro && messageIndex == 3))) {
      /* switch that checks if a button was
       pressed and responds to directional keys */
      if (messageIndex < messages.size() && messages.get(messageIndex).message == "")
        return;
      if (worldKeyPress) {
        if (key == CODED) {
          switch (keyCode) {
            //left key option
          case 37:
            //moves sprite left 30 pixels
            playa.sprite = loadImage("res/ash/spriteleft1.png");
            playa.posX -= 33/2;
            messageIndex++;
            if (playa.posX > 4 * tree.width
              && playa.posX < 14 * tree.width
              && playa.posY > 4 * tree.height - 33/2
              && playa.posY < 8 * tree.height - 33/2 ) {
              stepsTilEncounter--;
            }
            break;
            //up key option
          case 38:
            //moves sprite up 30 pixels
            playa.sprite = loadImage("res/ash/spriteback1.png");
            playa.posY -= 33/2;
            messageIndex++;
            if (playa.posX > 4 * tree.width
              && playa.posX < 14 * tree.width
              && playa.posY > 4 * tree.height - 33/2
              && playa.posY < 8 * tree.height - 33/2 ) {
              stepsTilEncounter--;
            }
            break;
            //right key option
          case 39:
            //moves sprite right 30 pixels
            playa.sprite = loadImage("res/ash/spriteright1.png");
            playa.posX += 33/2;
            messageIndex++;
            if (playa.posX > 4 * tree.width
              && playa.posX < 14 * tree.width
              && playa.posY > 4 * tree.height - 33/2
              && playa.posY < 8 * tree.height - 33/2 ) {
              stepsTilEncounter--;
            }
            break;
            //down key option
          case 40:
            //moves sprite down 30 pixels
            playa.sprite = loadImage("res/ash/sprite1.png");
            playa.posY += 33/2;
            messageIndex++;
            if (playa.posX > 4 * tree.width
              && playa.posX < 14 * tree.width
              && playa.posY > 4 * tree.height - 33/2
              && playa.posY < 8 * tree.height - 33/2 ) {
              stepsTilEncounter--;
            }
            break;
            //shift key
          case 16:
            //skips encounter steps
            currentScreen = new BattleScreen();
            break;
          }
        }
      }
      if (worldKeyRelease) {
        if (key == CODED) {
          switch (keyCode) {
          case 37:
            playa.sprite = loadImage("res/ash/spriteleft.png");
            break;
          case 38:
            //up
            playa.sprite = loadImage("res/ash/spriteback.png");
            break;
          case 39:
            //right
            playa.sprite = loadImage("res/ash/spriteright.png");
            break;
          case 40:
            //down
            playa.sprite = loadImage("res/ash/sprite.png");
            break;
          }
        }
      }
    }
    //resets keyPressed() options
    worldKeyPress = false;
    worldKeyRelease = false;
    //moves player one step closer to encounter


    //checks if player (playa? :P) is out of bounds
    if (playa.posX < 3 * tree.width
      || (intro && playa.posX > width - 4 * tree.width + 33/2)
      || playa.posY < 3 * tree.height - 33/2
      || playa.posY > height - 4 * tree.width) {
      textAlign(CENTER);
      textSize(20);
      text("You Got Lost!", width/2, height/2 - 100);
      textAlign(LEFT);
      //checks if player starts encounter based on steps til encounter
    } else {
      image(playa.sprite, playa.posX, playa.posY);
    }
    if (playa.posX >width)
      fadeToCredits = true;

    if ((messageIndex == 3 && !exitEvolve) && !intro)
      introEvolve = true;
    if (stepsTilEncounter <= 0) {
      if (opacity <= 255) {
        tint(255, opacity+=20);
        image(whiteScreen, 0, 0);
      } else
        currentScreen = new BattleScreen();
      //draws player in correct position
    } 
    if (introEvolve) {
      evolvecount+=1;
      image(evolveScreen, 0, 0);
      tint(255, opacity+=50);
      pindex = (pindex < 16 ? pindex+1 : pindex)%pikachuidle.length;
      imageMode(CENTER);
      image(pikachuidle[pindex], width/2, height/2);
      imageMode(CORNER);
      for (int s = 0; s<sparklesn; s++) {
        image(sparkle, sparklesx[s], sparklesy[s]);
        image(sparkle2, sparkles2x[s], sparkles2y[s]);
        image(sparkle3, sparkles3x[s], sparkles3y[s]);
        sparklesy[s]-=sparklesv[s];
        sparkles2y[s]-=sparklesv[s];
        sparkles3y[s]-=sparklesv[s];
      }
      if (evolvecount>60) {
        imageMode(CENTER);
        image(glow, width/2, height/2, glowsize+=20, glowsize+=20);
        imageMode(CORNER);
        if (glowsize >=1050) {
          exitEvolve = true;
          introEvolve = false;
        }
      }
    } 
    if (exitEvolve) {
      evolvecount+=1;
      tint(255, 255);
      image(evolveScreen, 0, 0);
      rindex = (rindex < 38 ? rindex+1 : rindex)%godhelpme.length;
      imageMode(CENTER);
      image(godhelpme[rindex], width/2-30, height/2-20);
      imageMode(CORNER);
      if (evolvecount>120) {
        tint(255, opacity3-=50);
        image(whiteScreen, 0, 0);
        if (opacity3<=-400) {
          messageIndex=4;
          if (evolvecount>200) {
            exitEvolve = false;
            opacity = 0;
          }
        }
      }
    }
    if (fadeToCredits) {
      tint(255, opacity+=10);
      image(blackScreen, 0, 0);
      if (opacity >=255) {
        currentScreen = new CreditsScreen();
      }
    }
    tint(255, 255);
  }
}
void keyReleased() {
  if (currentScreen instanceof WorldScreen) {
    worldKeyRelease = true;
  }
}

// all the important neato opening stuff goes here
class OpeningScreen extends Screen {
  private PImage grass;
  private PImage raindrop3;
  private PImage raindrop2;
  private PImage raindrop;
  private PImage leaves;
  private PImage plants;
  private PImage water;
  private PImage backlayer;
  private PImage background;
  private PImage bg;
  private PImage names;
  private PImage whitescreen;
  private PImage bg2;
  private PImage red;
  private PImage eyes;
  private PImage logo;
  private PImage logo2;
  private PImage bubbles;
  private PImage bubbles2;
  private PImage startbutton;
  private boolean redon = false;
  private boolean drawStart = true;

  private float rainx = 0, rainy = -700, nameopacity = 255, bgy = -200, white = 0;
  private float watery =-700, plantsy =-700, leavesy =-700, grassy =-700;
  private float rain2y = -700, rain3y = -700, backgroundy = -100, backlayery=-700;
  private float backlayeryt = 0, bg2o = 0, redo = 0, logoy = 50, logo2y = 60;
  private int bubblesn = 15;
  private float[] bubblesx = new float[bubblesn];
  private float[] bubblesy = new float[bubblesn];
  private float[] bubblesvy = new float[bubblesn];
  private float[] bubblesvx = new float[bubblesn];
  private float[] bubbles2x = new float[bubblesn];
  private float[] bubbles2y = new float[bubblesn];
  private float[] bubblesvy2 = new float[bubblesn];
  private float[] bubblesvx2 = new float[bubblesn];

  public OpeningScreen() {
    for (int i=0; i<bubblesn; i++) {
      bubblesx[i]=random(0, 600);
      bubblesy[i]= random(0, 400);
      bubbles2x[i]=random(-100, 600);
      bubbles2y[i]= random(0, 400);
      bubblesvy[i]=random(.1, 1.5);
      bubblesvx[i]=random(-1, 1);
      bubblesvy2[i]=random(.1, 1.5);
      bubblesvx2[i]=random(-1, 1);
    }
    grass = loadImage("res/op/1_grass1.png");
    raindrop3 = loadImage("res/op/2_raindrop3.png");
    raindrop2 = loadImage("res/op/3_raindrop2.png");
    raindrop = loadImage("res/op/4_raindrop.png");
    leaves = loadImage("res/op/5_leaves.png");
    plants = loadImage("res/op/6_plants.png");
    water = loadImage("res/op/7_water.png");
    backlayer = loadImage("res/op/8_backlayer.png");
    background = loadImage("res/op/9_background.png");
    bg = loadImage("res/op/10_bg.png");
    names = loadImage("res/op/11_names.png");
    whitescreen = loadImage("res/op/12_white.png");
    bg2 = loadImage("res/op/13_bg2.png");
    red = loadImage("res/op/14_red.png");
    eyes = loadImage("res/op/15_eyes.png");
    logo = loadImage("res/op/16_logo.png");
    logo2 = loadImage("res/op/17_logo2.png");
    bubbles = loadImage("res/op/18_bubble1.png");
    bubbles2 = loadImage("res/op/19_bubble2.png");
    startbutton = loadImage("res/op/20_start.png");
  }
  public void drawScreen() {
    image(background, 0, backgroundy);
    image(bg, 0, bgy);
    image(backlayer, 0, backlayery);
    image(water, 0, watery);
    image(plants, 0, plantsy);
    image(leaves, 0, leavesy);
    image(raindrop, rainx, rainy);
    tint(255, nameopacity);
    image(names, 0, -700);
    tint(255, 255);
    image(raindrop2, 0, rain2y);
    image(raindrop3, 0, rain3y);
    image(grass, 0, grassy);
    tint(255, white);
    image(whitescreen, 0, 0);
    tint(255, bg2o);
    image(bg2, 0, 0);
    tint(255, redo);
    image(red, 0, 0);
    tint(255, bg2o);
    image(eyes, 0, 0);
    image(logo, 0, logoy);
    image(logo2, 0, logo2y);
    tint(255, 255);
    if (playopening) {
      nameopacity-=10;
      if (nameopacity<0) {
        rainx-=2;
        rainy+=1;
        if (rainx<-101) {
          rainx = -100;
          rainy +=5;
          if (rainy>-400) {
            rain2y +=5;
            rain3y +=7;
            if (rain2y > -350) {
              rain2y +=7;
              grassy +=3;
              watery +=3;
              plantsy+=3;
              leavesy +=4;
              backlayery +=2.5;
              bgy +=2.5;
              if (backlayery > -150) {
                backlayeryt+=1;
                if (backlayeryt>40) {
                  white +=5;
                  backlayery -=2.4;
                  if (white >400) {
                    bg2o +=5;
                    logoy -=5;
                    logo2y -=6;
                    openingdone = true;
                    //if red is off and red is not visible
                    if (redo<256 && redon ==false) {
                      redo +=2;
                    }
                    //when red is visible, redon becomes true
                    if (redo==256) {
                      redon= true;
                    }
                    if (redon) {
                      redo -=2;
                    }
                    if (redo==0) {
                      redon=false;
                    }
                    if (frameCount % 30 == 0)
                      drawStart = !drawStart;
                    if (drawStart) {
                      image(startbutton, 0, -100);
                    }
                    for (int i = 0; i<bubblesn; i++) {
                      image(bubbles, bubblesx[i], bubblesy[i]);
                      image(bubbles2, bubbles2x[i], bubbles2y[i]);
                      bubbles2y[i] -= bubblesvy2[i];
                      bubblesx[i] += bubblesvx2[i];
                      bubblesy[i] -= bubblesvy[i];
                      bubblesx[i] += bubblesvx[i];
                      if (bubblesy[i]<-10) {
                        bubblesy[i]=420;
                        bubblesx[i]=random(-100, 600);
                      }
                      if (bubbles2y[i]<-10) {
                        bubbles2y[i]=420;
                        bubbles2x[i]=random(-100, 600);
                      }
                    }
                    if (logoy < 0) {
                      logoy = 0;
                      if (logo2y < 0) {
                        logo2y = 0;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}