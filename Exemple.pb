
If InitSprite()=0 Or InitKeyboard()=0 Or InitMouse()
    If OpenWindow(0, 0, 0, 1280, 800, "Exemple", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)=0 Or OpenWindowedScreen(WindowID(0), 0, 0, 1280, 800)=0
        MessageRequester("Error","Error can't open windowed screen")
    EndIf
EndIf

Global SpriteP.i=CreateSprite(#PB_Any,1,1,#PB_Sprite_PixelCollision)
StartDrawing(SpriteOutput(SpriteP)):Box(0,0,1,1,#White):StopDrawing()


ResX.i=1280
IncludeFile "Sprite.pb"



;Exemple
;charge les animations depuis la sprite-sheet
;load animation from SpriteSheet
For k=1 To 2
    Read.s Anim.s
    Read.s Spritesheet.s
    Read.s layer.s
    Read.s Delay.s
    CreateAnimation(Anim)
    Repeat
        Read.s subanim.s
        If subanim="End":Break:EndIf
        Read.s Line.s
        AddSubAnimation(Anim,subanim)
        AddSpriteSheet(Anim,subanim,Spritesheet,Val(Line),#LeftBottom,#PB_Sprite_PixelCollision)
    ForEver
    SetLayer(Anim,Val(layer))
    SetFrameSpeed(Anim,Val(delay))
Next k
DataSection
    ;Hero (Name, spritesheet image, order display, delay between frames
    Data.s "Hero","SpriteSheet1.png","10","100"
    ;Hero Subanimation (Name, line on spritesheet)
    Data.s "Appear","1","Appear","2","Run","3","Jump","4","Squat","5","Kick","6","Punch","7"
    Data.s "HKick","8","Fight","9","Fight","10","HPunch","20","HPunch","21","Idle","37"
    Data.s "Ultime","40","Ultime","41","Ultime","42","Ultime","43","Ultime","44","Ultime","45"
    Data.s "End"  
    
    ;Blast
    Data.s "Blast","SpriteSheet1.png","11","100"
    ;blast Subanimation
    Data.s "Blast","11"
    Data.s "End"
EndDataSection

SetCoordinate("Hero",300,600)
RunAnimation("Hero","Appear",10,2)

DuplicateAnimation("Hero","Mob",1)
ChangeColor("Mob",$3050c0,$FF0000)
SetCoordinate("Mob",400,600)
FlipAnimation("Mob",-1,0)
RunAnimation("Mob","Appear",10,2)

CreateAnimation("Fond1")
AddSubAnimation("Fond1","Fond1")
AddSprite("Fond1","Fond1","layer11.png",$ca04fb,#PB_Sprite_PixelCollision)
setlayer("Fond1",0)
SetFrameSpeed("Fond1",10)
RunAnimation("Fond1","Fond1",10,0,-1,#OnceAndStuck)

CreateAnimation("Fond2")
AddSubAnimation("Fond2","Fond1")
AddSprite("Fond2","Fond1","layer0.png",$ca04fb,#PB_Sprite_PixelCollision)
setlayer("Fond2",3)
setcoordinate("Fond2",0,800-AnimationHeight("Fond2"))
SetFrameSpeed("Fond2",10)
RunAnimation("Fond2","Fond1",10,0,-1,#OnceAndStuck)

CreateAnimation("Fond3")
AddSubAnimation("Fond3","Fond1")
AddSprite("Fond3","Fond1","layer1.png",$ca04fb,#PB_Sprite_PixelCollision)
setlayer("Fond3",1)
setcoordinate("Fond3",0,400)
SetFrameSpeed("Fond3",10)
RunAnimation("Fond3","Fond1",10,0,-1,#OnceAndStuck)

CreateAnimation("Fond4")
AddSubAnimation("Fond4","Fond1")
AddSprite("Fond4","Fond1","layer2.png",$ca04fb,#PB_Sprite_PixelCollision)
setlayer("Fond4",2)
setcoordinate("Fond4",0,800-AnimationHeight("Fond4"))
SetFrameSpeed("Fond4",10)
RunAnimation("Fond4","Fond1",10,0,-1,#OnceAndStuck)

ammunition=100
Repeat
    Repeat:Until WindowEvent()=0
    ExamineKeyboard()
    FlipBuffers()
    ClearScreen(RGB(128,128,128))
    ;Affiche toutes les animations
    DisplayAnim()
    
    If KeyboardPushed(#PB_Key_Right) And IsAnimation("Hero","Run")=-1
        If IsAnimation("Hero","Jump")=-1:RunAnimation("Hero","Run",10,2):EndIf
        FlipAnimation("Hero",1,0)
        SetMoveX("Hero",XAnimation("Hero")+100)
    EndIf
    If KeyboardPushed(#PB_Key_Left) And IsAnimation("Hero","Run")=-1
        If IsAnimation("Hero","Jump")=-1:RunAnimation("Hero","Run",10,2):EndIf
        FlipAnimation("Hero",-1,0)
        SetMoveX("Hero",XAnimation("Hero")-100)
    EndIf
    If KeyboardPushed(#PB_Key_Down) And IsAnimation("Hero")=-1:RunAnimation("Hero","Squat"):EndIf
    If KeyboardPushed(#PB_Key_Up) And IsAnimation("Hero","Jump")=-1
        RunAnimation("Hero","Jump",10,2)
        SetJump("Hero",40,2,YAnimation("Hero"))
    EndIf
    If KeyboardPushed(#PB_Key_Space) And IsAnimation("Hero","Fight")=-1 And IsAnimation("Hero","Punch")=-1 And IsAnimation("Hero","Kick")=-1 And IsAnimation("Hero","HKick")=-1
        If ammunition And blast=0
            RunAnimation("Hero","Fight")
        Else
            r=(r+1)%5
            Select r
                Case 0
                    RunAnimation("Hero","Punch")
                Case 1
                    RunAnimation("Hero","Kick")
                Case 2
                    RunAnimation("Hero","HKick")
                Case 3
                    RunAnimation("Hero","HPunch")
            EndSelect
        EndIf
    EndIf
    If KeyboardPushed(#PB_Key_LeftControl)
        RunAnimation("Hero","Ultime")
    EndIf
    
    If IsAnimation("Hero","Fight")=4
        If blast=0
            blast=1
            ammunition-1
            FlipAnimation("Blast",AnimationSensH("Hero"),0)
            If AnimationSensH("Hero")=1
                SetCoordinate("Blast",XAnimation("Hero")+50,YAnimation("Hero")-10)
                SetMoveX("Blast",Resx+1,30,20)
            Else
                SetCoordinate("Blast",XAnimation("Hero")-20,YAnimation("Hero")-10)
                SetMoveX("Blast",-AnimationWidth("Hero")-1,30,20)
            EndIf
            RunAnimation("Blast","Blast",-1,-1,-1,#OnceAndStuck)
        EndIf
    EndIf
    
    If blast=1 And (XAnimation("Blast")>ResX Or XAnimation("Blast")<-AnimationWidth("Blast"))
        PauseAnimation("Blast")
        HideAnimation("Blast")
        blast=0
    EndIf
    
    If IsAnimation("Hero")=-1:RunAnimation("Hero","Idle"):EndIf
    AnimationScroll("Fond2", 2, 0)
    AnimationScroll("Fond3", 3, 0)
    AnimationScroll("Fond4", 1, 0)

Until KeyboardPushed(#PB_Key_Escape)
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 78
; FirstLine = 63
; Folding = ----
; EnableAsm
; EnableXP