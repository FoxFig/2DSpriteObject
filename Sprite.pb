UsePNGImageDecoder()
UseJPEGImageDecoder()

Enumeration
    #None
    #LeftBottom
    #RightBottom
    #CenterBottom
    #LeftUp
    #RightUp
    #CenterUp
    #Center
    #RightCenter
    #LeftCenter
EndEnumeration
;Animation Read Option
Enumeration
    #Once
    #OnceAndStuck
    #Loop
EndEnumeration

;{ Flip sprite by Danilo // Inverse un Sprite, procedure de Danilo
Import ""
    PB_Screen_Direct3DDevice.IDirect3DDevice9
EndImport
Enumeration D3DCULL
    #D3DCULL_NONE = 1
    #D3DCULL_CW   = 2
    #D3DCULL_CCW  = 3
EndEnumeration
#D3DRS_CULLMODE   = 22
Procedure SetCullMode(MODE)
    ; MODE 0 = OFF
    ; MODE 1 = ON
    If PB_Screen_Direct3DDevice
        If MODE : MODE = #D3DCULL_CCW
        Else    : MODE = #D3DCULL_NONE
        EndIf
        PB_Screen_Direct3DDevice\SetRenderState(#D3DRS_CULLMODE,MODE)
    EndIf
EndProcedure
SetCullMode(0)
;}

Structure Sprite
    Number.i
    ShiftX.i
    ShiftY.i
    OShiftX.i
    OShiftY.i
    FlipH.i
    FlipV.i
    Cx.i[4]
    Cy.i[4]
    delay.q
EndStructure
Structure Animation1
    AutoAdjust.i
    ModeLoop.i
    List Sprite.sprite()
EndStructure
Structure AnimationMap
    Animation.s
    CurrentAnimation.s
    CurrentAnimationFrame.i ;-1=finished else =frame number 
    X.f
    Y.f
    
    GoalX.f
    GoalY.f
    
    JumpY.f
    GravityY.f
    
    SpriteCollision.i
    
    Show.i
    Pause.i
    MaxSizeX.i
    MaxSizeY.i
    StepFade.i
    StepMove.i
    NextTimer.q
    
    NextTimerFade.q
    DelayFade.q
    NextTimerMove.q
    DelayMove.q
    opacity.i
    *Pointer
    Map Anim.Animation1()
EndStructure
Structure AnimationList
    Animation.s
    DisplayLayer.i
EndStructure
Structure Pixel
    Pixel.l
EndStructure

Global NewList SpriteList.AnimationList()
Global NewMap SpriteMap.AnimationMap()

;define pixelsprite for mouse collisions
; Global SpriteP.i=CreateSprite(#PB_Any,1,1,#PB_Sprite_PixelCollision)
; StartDrawing(SpriteOutput(SpriteP)):Box(0,0,1,1,#White):StopDrawing()

;specify the display order : layer 0 is display first then layer 1, then layer 2 etc...
;Spécifie l'ordre d'affiche des animations. au premier plan layer 0 puis layer 1 puis layer 2 etc...
Procedure SetLayer(Animation.s,Layer.i)
    If FindMapElement(SpriteMap(),Animation)
        ChangeCurrentElement(SpriteList(),SpriteMap()\Pointer)
        SpriteList()\DisplayLayer=Layer
        SortStructuredList(SpriteList(),#PB_Sort_Ascending,OffsetOf(AnimationList\DisplayLayer),#PB_Integer)
    EndIf
EndProcedure

;set delay between frames on the subanimation specified
;if frame<>-1, set the delay only for one specific frame
;Définie le délai entre les images de la sous-animation
;si Frame<>-1, affecte uniquement la frame spécifiée
Procedure SetFrameSpeed(Animation.s,delay.q,SubAnimation.s="",frame.i=-1)
    If FindMapElement(SpriteMap(),Animation)
        If SubAnimation<>""
            If FindMapElement(SpriteMap()\Anim(),SubAnimation)
                If frame=-1
                    ForEach SpriteMap()\Anim()\Sprite()
                        SpriteMap()\Anim()\Sprite()\delay=delay
                    Next
                Else
                    SelectElement(SpriteMap()\Anim()\Sprite(),frame)
                    SpriteMap()\Anim()\Sprite()\delay=delay
                EndIf
            EndIf
        Else
           ForEach SpriteMap()\Anim()
                If frame=-1
                    ForEach SpriteMap()\Anim()\Sprite()
                        SpriteMap()\Anim()\Sprite()\delay=delay
                    Next
                Else
                    SelectElement(SpriteMap()\Anim()\Sprite(),frame)
                    SpriteMap()\Anim()\Sprite()\delay=delay
                EndIf               
           Next    
        EndIf
    EndIf
EndProcedure

;Replace SourceColor by TargetColor in a sprite
;Remplace la couleur Source par la couleur Target dans un sprite
Procedure ChangeColor(Animation.s,SourceColor.i,TargetColor.i)
    If FindMapElement(SpriteMap(),Animation)
        ForEach SpriteMap()\Anim()
            ForEach SpriteMap()\Anim()\Sprite()
                sprite=SpriteMap()\Anim()\Sprite()\Number
                If StartDrawing(SpriteOutput(sprite))
                    Buffer      = DrawingBuffer()             ; Get the start address of the sprite buffer
                    Pitch       = DrawingBufferPitch()        ; Get the length (in byte) took by one horizontal line
                    PixelFormat = DrawingBufferPixelFormat()  ; Get the pixel format. 
                    spH=SpriteHeight(sprite)-1
                    spW=SpriteWidth(sprite)-1
                    For y = 0 To spH           
                        *Line.Pixel = Buffer+Pitch*y
                        For x = 0 To spW
                            If ($0000000000FFFFFF & *Line\Pixel)=SourceColor
                                *Line\Pixel=TargetColor
                            EndIf
                            *Line+4
                        Next
                    Next
                    StopDrawing()
                EndIf
            Next
        Next
    EndIf
EndProcedure

;Create a new animation
;Créé une nouvelle animation
Procedure CreateAnimation(Animation.s)
    AddMapElement(SpriteMap(),Animation)
    SpriteMap()\Animation=Animation
    LastElement(SpriteList())
    *a=AddElement(SpriteList())
    SpriteList()\Animation=Animation
    SpriteMap()\Pointer=*a
EndProcedure

;duplicate an animation
;duplique une animation
Procedure DuplicateAnimation(Animation.s,CopiedAnimation.s,IndependantSprite.u)
    AddMapElement(SpriteMap(),CopiedAnimation)
    spritemap(CopiedAnimation)=SpriteMap(Animation)
    SpriteMap()\Animation=CopiedAnimation
    LastElement(SpriteList())
    *a=AddElement(SpriteList())
    SpriteList()\Animation=CopiedAnimation
    SpriteMap()\Pointer=*a
    ChangeCurrentElement(SpriteList(),SpriteMap(Animation)\Pointer)
    DisplayLayer=SpriteList()\DisplayLayer
    SetLayer(CopiedAnimation,DisplayLayer)
    If IndependantSprite=1
        ForEach spritemap()\Anim()
            ForEach spritemap()\Anim()\Sprite()
                sprite=spritemap()\Anim()\Sprite()\Number
                key.s=MapKey(spritemap()\Anim())
                PushListPosition(spritemap()\Anim()\Sprite())
                indexlist=ListIndex(spritemap()\Anim()\Sprite())
                If FindMapElement(SpriteMap(),CopiedAnimation) And FindMapElement(SpriteMap()\Anim(),key)
                    SelectElement(spritemap()\Anim()\Sprite(),indexlist)
                    spritemap()\Anim()\Sprite()\Number=CopySprite(sprite,#PB_Any)
                EndIf
                PopListPosition(spritemap()\Anim()\Sprite())
            Next
        Next
    EndIf
EndProcedure

;Destroy an animation and its subanimations
;Détruit une animation et ses sous-animations
Procedure DeleteAnimation(Animation.s)
    If FindMapElement(SpriteMap(),Animation)
        ChangeCurrentElement(SpriteList(),SpriteMap()\Pointer)
        DeleteElement(SpriteList())
        FreeList(SpriteMap()\Anim()\Sprite())
        FreeMap(SpriteMap()\Anim())
        DeleteMapElement(SpriteMap())
    EndIf
EndProcedure

;Add a new subanimation
;Ajoute une sous-animation
Procedure AddSubAnimation(Animation.s,SubAnimation.s)
    If FindMapElement(SpriteMap(),Animation) 
        If FindMapElement(SpriteMap()\Anim(),SubAnimation)=0
            AddMapElement(SpriteMap()\Anim(),SubAnimation)
            SpriteMap()\CurrentAnimationFrame=-1
            ProcedureReturn 1
        EndIf
    EndIf
    ProcedureReturn
EndProcedure

;Add a single sprite to a subanimation
;Ajoute un sprite à une animation
Procedure AddSprite(Animation.s,SubAnimation.s,PathPlusName.s,TransparentColor.i,mode.i=0)
    If FindMapElement(SpriteMap(),Animation) And FindMapElement(SpriteMap()\Anim(),SubAnimation)
        spritemap()\SpriteCollision=mode
        PushListPosition(SpriteMap()\Anim()\Sprite())
        LastElement(SpriteMap()\Anim()\Sprite())
        AddElement(SpriteMap()\Anim()\Sprite())
        SpriteMap()\Anim()\Sprite()\Number=LoadSprite(#PB_Any,PathPlusName,mode)
        TransparentSpriteColor(SpriteMap()\Anim()\Sprite()\Number,TransparentColor)
        SpriteMap()\Anim()\Sprite()\Cx[1]=SpriteWidth(SpriteMap()\Anim()\Sprite()\Number)
        SpriteMap()\Anim()\Sprite()\Cx[2]=SpriteWidth(SpriteMap()\Anim()\Sprite()\Number)
        SpriteMap()\Anim()\Sprite()\Cy[2]=SpriteHeight(SpriteMap()\Anim()\Sprite()\Number)
        SpriteMap()\Anim()\Sprite()\Cy[3]=SpriteHeight(SpriteMap()\Anim()\Sprite()\Number)
        SpriteMap()\Anim()\Sprite()\FlipH=1
        SpriteMap()\Anim()\Sprite()\FlipV=1
        SpriteMap()\Show=1
        spritemap()\opacity=255
        SpriteMap()\Anim()\AutoAdjust=-1
        If SpriteWidth(SpriteMap()\Anim()\Sprite()\Number)>SpriteMap()\MaxSizeX:SpriteMap()\MaxSizeX=SpriteWidth(SpriteMap()\Anim()\Sprite()\Number):EndIf
        If SpriteHeight(SpriteMap()\Anim()\Sprite()\Number)>SpriteMap()\MaxSizeY:SpriteMap()\MaxSizeY=SpriteHeight(SpriteMap()\Anim()\Sprite()\Number):EndIf
        PopListPosition(SpriteMap()\Anim()\Sprite())
    Else
        ProcedureReturn 0                 
    EndIf
    ProcedureReturn 1
EndProcedure

Structure X
    XMin.i
    XMax.i
    YMin.i
    YMax.i
EndStructure
Structure Y
    Ymin.i
    Ymax.i
    List Sprites.X()
EndStructure
Structure Ans
    XSizeMax.i
    YSizeMax.i
    List AnimeSheet.Y()
EndStructure
Macro ExamineSpriteSheet(Animation,PathPlusName)
    Static NewMap Ans.Ans()
    img.i=LoadImage(#PB_Any,PathPlusName)
    StartDrawing(ImageOutput(img))
    EmptyColor=Point(0,0)       
    If FindMapElement(Ans(),PathPlusName)=0
        AddMapElement(Ans(),PathPlusName)
        IH.i=ImageHeight(img)-1
        IW.i=ImageWidth(img)-1
        new.i=0
        For j=0 To IH
            void.i=1
            For i=0 To IW
                If Point(i,j)<>EmptyColor
                    If new=0
                        new=1
                        AddElement(Ans()\AnimeSheet())
                        Ans()\AnimeSheet()\YMin=j
                    EndIf
                    void=0
                    Break
                EndIf       
            Next i
            If void=1 And new=1
                new=0
                Ans()\AnimeSheet()\YMax=j
                DeltaY.i=Ans()\AnimeSheet()\YMax-Ans()\AnimeSheet()\YMin
                If deltaY>Ans()\YSizeMax:Ans()\YSizeMax=DeltaY:EndIf
            EndIf
        Next j
        
        ;pour chaque ligne de sprite
        ForEach Ans()\AnimeSheet()
            new.i=0
            IW.i=ImageWidth(img)-1
            For i=0 To IW
                void.i=1
                For j=Ans()\AnimeSheet()\YMin To Ans()\AnimeSheet()\YMax
                    If Point(i,j)<>EmptyColor
                        If new=0
                            new=1
                            AddElement(Ans()\AnimeSheet()\Sprites())
                            Ans()\AnimeSheet()\Sprites()\XMin=i
                        EndIf
                        void=0
                        Break
                    EndIf       
                Next j
                If void=1 And new=1
                    new=0
                    Ans()\AnimeSheet()\Sprites()\XMax=i
                    DeltaX.i=Ans()\AnimeSheet()\Sprites()\XMax-Ans()\AnimeSheet()\Sprites()\XMin
                    If DeltaX>Ans()\XSizeMax:Ans()\XSizeMax=DeltaX:EndIf
                EndIf
            Next i

            ForEach Ans()\AnimeSheet()\Sprites()
                For j=Ans()\AnimeSheet()\Ymin To Ans()\AnimeSheet()\Ymax
                    void.i=1
                    For i=Ans()\AnimeSheet()\Sprites()\Xmin To Ans()\AnimeSheet()\Sprites()\Xmax
                        If Point(i,j)<>EmptyColor
                            void=0
                            If new=0
                                new=1
                                Ans()\AnimeSheet()\Sprites()\YMin=j
                                Break
                            EndIf
                        EndIf       
                    Next i
                    If void=1 And new=1
                        new=0
                        Ans()\AnimeSheet()\Sprites()\YMax=j
                    EndIf
                Next j
            Next
        Next
    EndIf
    StopDrawing()
EndMacro

;Add a subanimation from a spritesheet
;ajoute une sous-animation depuis une feuille de sprites
Procedure AddSpriteSheet(Animation.s,SubAnimation.s,PathPlusName.s,Line.i,AutoAdjust.i=-1,mode.i=0,TransparentColor.i=-1)
    ExamineSpriteSheet(Animation,PathPlusName)
    SelectElement(Ans()\AnimeSheet(),Line-1)
    If FindMapElement(SpriteMap(),Animation)
        SpriteMap()\MaxSizeX=Ans()\XSizeMax
        SpriteMap()\MaxSizeY=Ans()\YSizeMax
        SpriteMap()\opacity=255
        SpriteMap()\CurrentAnimationFrame=-1
    EndIf
    AddSubAnimation(Animation,SubAnimation)
    ForEach Ans()\AnimeSheet()\Sprites()
        OSizeX=Ans()\AnimeSheet()\sprites()\XMax-Ans()\AnimeSheet()\sprites()\XMin
        OSizeY=Ans()\AnimeSheet()\sprites()\YMax-Ans()\AnimeSheet()\sprites()\YMin
        sp1.i=CreateSprite(#PB_Any,OSizeX,OSizeY,mode)
        If TransparentColor=-1
            TransparentSpriteColor(sp1,EmptyColor)
        Else
            TransparentSpriteColor(sp1,TransparentColor)
        EndIf
            img2=GrabImage(img,#PB_Any,Ans()\AnimeSheet()\sprites()\XMin,Ans()\AnimeSheet()\sprites()\YMin,OSizeX,OSizeY)
            
            StartDrawing(SpriteOutput(sp1))
            DrawingMode(#PB_2DDrawing_AllChannels )
            DrawImage(ImageID(img2),0,0)
            StopDrawing()
            
            LastElement(SpriteMap()\Anim()\Sprite())
            AddElement(SpriteMap()\Anim()\Sprite())
            SpriteMap()\Anim()\Sprite()\FlipH=1
            SpriteMap()\Anim()\Sprite()\FlipV=1
            SpriteMap()\Anim()\Sprite()\Number=sp1
            SpriteMap()\Anim()\Sprite()\Cx[1]=SpriteWidth(SpriteMap()\Anim()\Sprite()\Number)
            SpriteMap()\Anim()\Sprite()\Cx[2]=SpriteWidth(SpriteMap()\Anim()\Sprite()\Number)
            SpriteMap()\Anim()\Sprite()\Cy[2]=SpriteHeight(SpriteMap()\Anim()\Sprite()\Number)
            SpriteMap()\Anim()\Sprite()\Cy[3]=SpriteHeight(SpriteMap()\Anim()\Sprite()\Number)
            
            FreeImage(img2)
        Next
    FreeImage(img)
    If AutoAdjust<>-1 And FindMapElement(SpriteMap(),Animation) And FindMapElement(SpriteMap()\Anim(),SubAnimation)
        spritemap()\SpriteCollision=mode
        SpriteMap()\Anim()\AutoAdjust=AutoAdjust
        ForEach SpriteMap()\Anim()
            ForEach SpriteMap()\Anim()\Sprite()
                SW.i=SpriteWidth(SpriteMap()\Anim()\Sprite()\Number)
                SH.i=SpriteHeight(SpriteMap()\Anim()\Sprite()\Number)
                If AutoAdjust=#RightBottom Or AutoAdjust=#RightUp
                    SpriteMap()\Anim()\Sprite()\ShiftX=SpriteMap()\MaxSizeX-SW
                ElseIf AutoAdjust=#CenterBottom Or AutoAdjust=#CenterUp Or AutoAdjust=#Center
                    SpriteMap()\Anim()\Sprite()\ShiftX=(SpriteMap()\MaxSizeX-SW)>>1
                ElseIf AutoAdjust=#LeftBottom Or AutoAdjust=#LeftUp
                    SpriteMap()\Anim()\Sprite()\ShiftX=0
                EndIf
                SpriteMap()\Anim()\Sprite()\OshiftX=SpriteMap()\Anim()\Sprite()\ShiftX

                If AutoAdjust=#LeftBottom Or AutoAdjust=#RightBottom Or AutoAdjust=#CenterBottom
                    SpriteMap()\Anim()\Sprite()\ShiftY=SpriteMap()\MaxSizeY-SH
                ElseIf AutoAdjust=#LeftCenter Or AutoAdjust=#RightCenter Or AutoAdjust=#Center
                    SpriteMap()\Anim()\Sprite()\ShiftY=(SpriteMap()\MaxSizeY-SH)>>1
                ElseIf AutoAdjust=#LeftUp Or AutoAdjust=#RightUp Or AutoAdjust=#CenterUp
                    SpriteMap()\Anim()\Sprite()\ShiftY=0
                EndIf
                SpriteMap()\Anim()\Sprite()\OshiftY=SpriteMap()\Anim()\Sprite()\ShiftY
            Next
        Next
        
    EndIf
    ProcedureReturn 1
EndProcedure

;Horizontal=-1 :flip animation Leftward
;Horizontal=1 :flip animation Rightward
;Vertical :Same Upward and Downward

;Horizontal=-1 :Inverse l'animation vers la gauche
;Horizontal=1 :Inverse l'animation vers la droite
;Vertical :idem vers le haut et le bas
Procedure FlipAnimation(Animation.s,Horizontal.i,Vertical.i)
    If FindMapElement(SpriteMap(),Animation) And FindMapElement(SpriteMap()\Anim(),SpriteMap()\CurrentAnimation)
        PushMapPosition(SpriteMap()\Anim())
        PushListPosition(SpriteMap()\Anim()\Sprite())
        ForEach SpriteMap()\Anim()
            ForEach SpriteMap()\Anim()\Sprite()
                Num.i=SpriteMap()\Anim()\Sprite()\Number
                If Horizontal=1 And SpriteMap()\Anim()\Sprite()\FlipH=-1
                    If SpriteMap()\Anim()\AutoAdjust=#LeftBottom Or SpriteMap()\Anim()\AutoAdjust=#LeftUp
                        SpriteMap()\Anim()\Sprite()\ShiftX=0
                    Else
                        SpriteMap()\Anim()\Sprite()\ShiftX=SpriteMap()\Anim()\Sprite()\OShiftX
                    EndIf
                    SpriteMap()\Anim()\sprite()\Cx[0]=0
                    SpriteMap()\Anim()\sprite()\Cx[1]=SpriteWidth(num)
                    SpriteMap()\Anim()\sprite()\Cx[2]=SpriteWidth(num)
                    SpriteMap()\Anim()\sprite()\Cx[3]=0
                    SpriteMap()\Anim()\Sprite()\FlipH=1
                ElseIf Horizontal=-1 And SpriteMap()\Anim()\Sprite()\FlipH=1
                    If SpriteMap()\Anim()\AutoAdjust=#LeftBottom Or SpriteMap()\Anim()\AutoAdjust=#LeftUp
                        SpriteMap()\Anim()\Sprite()\ShiftX=SpriteMap()\Anim()\Sprite()\OShiftX
                    Else
                        SpriteMap()\Anim()\Sprite()\ShiftX=0
                    EndIf
                    SpriteMap()\Anim()\sprite()\Cx[0]=SpriteWidth(num)
                    SpriteMap()\Anim()\sprite()\Cx[1]=0
                    SpriteMap()\Anim()\sprite()\Cx[2]=0
                    SpriteMap()\Anim()\sprite()\Cx[3]=SpriteWidth(num)
                    SpriteMap()\Anim()\Sprite()\FlipH=-1
                EndIf
                
                If Vertical=1 And SpriteMap()\Anim()\Sprite()\FlipV=-1
                    If SpriteMap()\Anim()\AutoAdjust=#LeftBottom Or SpriteMap()\Anim()\AutoAdjust=#RightBottom Or SpriteMap()\Anim()\AutoAdjust=#CenterBottom
                        SpriteMap()\Anim()\Sprite()\ShiftY=SpriteMap()\Anim()\Sprite()\OShiftY
                    Else
                        SpriteMap()\Anim()\Sprite()\ShiftY=0
                    EndIf
                    SpriteMap()\Anim()\sprite()\Cy[0]=0
                    SpriteMap()\Anim()\sprite()\Cy[1]=0
                    SpriteMap()\Anim()\sprite()\Cy[2]=SpriteHeight(num)
                    SpriteMap()\Anim()\sprite()\Cy[3]=SpriteHeight(num)
                    SpriteMap()\Anim()\Sprite()\FlipV=1
                    
                ElseIf Vertical=-1 And SpriteMap()\Anim()\Sprite()\FlipV=1
                    If SpriteMap()\Anim()\AutoAdjust=#LeftUp Or SpriteMap()\Anim()\AutoAdjust=#RightUp Or SpriteMap()\Anim()\AutoAdjust=#CenterUp
                        SpriteMap()\Anim()\Sprite()\ShiftY=SpriteMap()\Anim()\Sprite()\OShiftY
                    Else
                        SpriteMap()\Anim()\Sprite()\ShiftY=0
                    EndIf
                    SpriteMap()\Anim()\sprite()\Cy[0]=SpriteHeight(num)
                    SpriteMap()\Anim()\sprite()\Cy[1]=SpriteHeight(num)
                    SpriteMap()\Anim()\sprite()\Cy[2]=0
                    SpriteMap()\Anim()\sprite()\Cy[3]=0
                    SpriteMap()\Anim()\Sprite()\FlipV=-1
                EndIf
                x1=SpriteMap()\Anim()\sprite()\Cx[0]:y1=SpriteMap()\Anim()\sprite()\Cy[0]
                x2=SpriteMap()\Anim()\sprite()\Cx[1]:y2=SpriteMap()\Anim()\sprite()\Cy[1]
                x3=SpriteMap()\Anim()\sprite()\Cx[2]:y3=SpriteMap()\Anim()\sprite()\Cy[2]
                x4=SpriteMap()\Anim()\sprite()\Cx[3]:y4=SpriteMap()\Anim()\sprite()\Cy[3]
                TransformSprite(num,x1,y1,x2,y2,x3,y3,x4,y4)
            Next
        Next
        PopMapPosition(SpriteMap()\Anim())
        PopListPosition(SpriteMap()\Anim()\Sprite())
    EndIf    
EndProcedure

;Play Subanimation
;if frame=-1, the whole animation is played, else it begins at frame number.
;ModeLoop=#once Animation is played only once else =#Loop it will loop.
;joue la sous-animation
;si frame=-1, l'animation complète est jouée, sinon l'animation commence à la frame spécifiée
;ModeLoop=#once l'animation sera joué une seule fois, sinon elle bouclera avec #Loop ou s'arretera avec #OnceAndStuck
Procedure RunAnimation(Animation.s,SubAnimation.s,delay.q=-1,StepMove.i=-1,frame.i=-1,ModeLoop.i=#Once)
    If FindMapElement(SpriteMap(),Animation) And FindMapElement(SpriteMap()\Anim(),SubAnimation)
        If frame=-1
            FirstElement(SpriteMap()\Anim()\sprite())
            SpriteMap()\CurrentAnimationFrame=0
        Else
            SelectElement(SpriteMap()\Anim()\Sprite(),frame)
            SpriteMap()\CurrentAnimationFrame=frame
        EndIf
        SpriteMap()\CurrentAnimation=SubAnimation
        SpriteMap()\Anim()\ModeLoop=ModeLoop
        SpriteMap()\Show=1
        SpriteMap()\Pause=0
        If delay<>-1
            SpriteMap()\DelayMove=delay
        EndIf
        If StepMove<>-1
            SpriteMap()\StepMove=StepMove
        EndIf
    Else
        ProcedureReturn 0
    EndIf
    ProcedureReturn 1
EndProcedure

Procedure SetFadeOut(Animation.s,timer.q,StepFade.i)
    If FindMapElement(SpriteMap(),Animation)
        SpriteMap()\DelayFade=-timer
        SpriteMap()\NextTimerFade=ElapsedMilliseconds()-timer
        SpriteMap()\StepFade=StepFade
    EndIf
EndProcedure

Procedure SetFadeIn(Animation.s,timer.q,StepFade.i)
    If FindMapElement(SpriteMap(),Animation)
        SpriteMap()\DelayFade=timer
        SpriteMap()\NextTimerFade=ElapsedMilliseconds()+timer
        SpriteMap()\StepFade=StepFade
    EndIf
EndProcedure

Procedure SetMoveX(Animation.s,GoalX.f,delay.q=-1,StepMove.i=-1)
    If FindMapElement(SpriteMap(),Animation)
        SpriteMap()\GoalX=GoalX
        If delay<>-1
            SpriteMap()\DelayMove=delay
        EndIf
        If StepMove<>-1
            SpriteMap()\StepMove=StepMove
        EndIf        
    EndIf
EndProcedure

Procedure SetMoveY(Animation.s,GoalY.f,delay.q=-1,StepMove.i=-1)
    If FindMapElement(SpriteMap(),Animation)
        SpriteMap()\GoalY=GoalY
        If delay<>-1
            SpriteMap()\DelayMove=delay
        EndIf
        If StepMove<>-1
            SpriteMap()\StepMove=StepMove
        EndIf        
    EndIf
EndProcedure

Procedure SetJump(Animation.s,JumpY.f,gravityY.f,GoalY.f,delay.q=-1,StepMove.i=-1)
    If FindMapElement(SpriteMap(),Animation)
        SpriteMap()\JumpY=JumpY
        SpriteMap()\GravityY=gravityY
        If delay<>-1
            SpriteMap()\DelayMove=delay
        EndIf
        If StepMove<>-1
            SpriteMap()\StepMove=StepMove
        EndIf
    EndIf
EndProcedure
    
;display all animations on screen except hide ones.
;ModeLoop=#once l'animation sera jouée une seule fois, sinon elle bouclera avec #Loop
;ModeLoop=#onceAndStuck l'animation sera jouée une seule fois, Puis restera sur la dernière image
Procedure DisplayAnim()
    ForEach SpriteList()
        Animation.s=SpriteList()\Animation
        If FindMapElement(SpriteMap(),Animation) And FindMapElement(SpriteMap()\Anim(),SpriteMap()\CurrentAnimation)
            If SpriteMap()\Show=0:Continue:EndIf
            DisplayTransparentSprite(SpriteMap()\Anim()\Sprite()\Number,SpriteMap()\X+SpriteMap()\Anim()\Sprite()\ShiftX,SpriteMap()\Y+SpriteMap()\Anim()\Sprite()\ShiftY,SpriteMap()\Opacity)
            If SpritePixelCollision(SpriteMap()\Anim()\Sprite()\Number,SpriteMap()\X+SpriteMap()\Anim()\Sprite()\ShiftX,SpriteMap()\Y+SpriteMap()\Anim()\Sprite()\ShiftY,SpriteP,MouseX(),MouseY())
                MouseSpriteCollision=SpriteMap()\Anim()\Sprite()\Number
            EndIf    
            ;image framing
            If SpriteMap()\NextTimer<=ElapsedMilliseconds()
                If NextElement(SpriteMap()\Anim()\Sprite())=0
                    If SpriteMap()\Anim()\ModeLoop=#Once
                        SpriteMap()\CurrentAnimationFrame=-1  
                    ElseIf SpriteMap()\Anim()\ModeLoop=#OnceAndStuck
                        SpriteMap()\Pause=1
                    Else ;loop
                        SpriteMap()\CurrentAnimationFrame=0
                        FirstElement(SpriteMap()\Anim()\Sprite())
                    EndIf
                Else
                    SpriteMap()\CurrentAnimationFrame+1
                EndIf
                SpriteMap()\NextTimer=ElapsedMilliseconds()+SpriteMap()\Anim()\Sprite()\Delay
            EndIf
            ;Fading
            If SpriteMap()\DelayFade And SpriteMap()\NextTimerFade<=ElapsedMilliseconds()
                If SpriteMap()\DelayFade>0
                    SpriteMap()\NextTimerFade=ElapsedMilliseconds()+Abs(SpriteMap()\DelayFade)
                    If SpriteMap()\opacity<255-SpriteMap()\StepFade
                        SpriteMap()\opacity+SpriteMap()\StepFade
                    Else
                        SpriteMap()\opacity=255
                        SpriteMap()\DelayFade=0
                    EndIf
                Else
                    If SpriteMap()\opacity>SpriteMap()\StepFade
                        SpriteMap()\opacity-SpriteMap()\StepFade
                    Else
                        SpriteMap()\opacity=0
                        SpriteMap()\DelayFade=0
                    EndIf
                EndIf
            EndIf
            ;Move
            If SpriteMap()\DelayMove And SpriteMap()\NextTimerMove<=ElapsedMilliseconds()
                SpriteMap()\NextTimerMove=ElapsedMilliseconds()+SpriteMap()\DelayMove
                ;Horizontal Move
                If SpriteMap()\X<>SpriteMap()\goalX
;                     Debug Str(SpriteMap()\X)+"/"+Str(SpriteMap()\goalX)+"/"+Str(SpriteMap()\StepMove)
                    Flox=SpriteMap()\X-SpriteMap()\goalX
                    SpriteMap()\X-SpriteMap()\StepMove*Sign(Flox)
                    If (Sign(FloX)=-1 And SpriteMap()\X>SpriteMap()\GoalX) Or (Sign(FloX)=1 And SpriteMap()\X<SpriteMap()\GoalX)
                        SpriteMap()\X=SpriteMap()\GoalX
                    EndIf
                EndIf
                ;Vertical Move
                If SpriteMap()\GravityY=0.0 And SpriteMap()\Y<>SpriteMap()\goalY
                    FloY=SpriteMap()\Y-SpriteMap()\goalY
                    SpriteMap()\Y-SpriteMap()\StepMove*Sign(floy)
                    If (Sign(FloY)=-1 And SpriteMap()\Y>SpriteMap()\GoalY) Or (Sign(FloY)=1 And SpriteMap()\Y<SpriteMap()\GoalY)
                        SpriteMap()\Y=SpriteMap()\GoalY
                    EndIf
                EndIf   
                ;#Jump
                If SpriteMap()\GravityY<>0.0
                    SpriteMap()\JumpY-SpriteMap()\GravityY
                    SpriteMap()\Y-SpriteMap()\JumpY
                    If SpriteMap()\Y>SpriteMap()\goalY
                        Spritemap()\Y=SpriteMap()\GoalY
                        SpriteMap()\GravityY=0.0
                    EndIf
                EndIf
            EndIf
        EndIf
    Next
    ProcedureReturn MouseSpriteCollision
EndProcedure

;Return -1 if animation is finished or not currently beeing played.
;Else, Return the current frame number of the animation.
;retourne -1 si l'animation est terminé ou n'est pas jouée
;sinon, retourne le numéro de l'image en cours
Procedure IsAnimation(Animation.s,SubAnimation.s="")
    If FindMapElement(SpriteMap(),Animation)
        If SubAnimation.s="":SubAnimation=SpriteMap()\CurrentAnimation:EndIf
        If FindMapElement(SpriteMap()\Anim(),SubAnimation)
            If SubAnimation=SpriteMap()\CurrentAnimation And SpriteMap()\CurrentAnimationFrame<>-1
                ProcedureReturn SpriteMap()\CurrentAnimationFrame
            Else
                ProcedureReturn -1
            EndIf
        EndIf
    EndIf
EndProcedure

;Set Animation to coordinates X,Y
;définie les coordonées X et Y
Procedure SetCoordinate(Animation.s,X.i,Y.i)
    If FindMapElement(SpriteMap(),Animation)   
        SpriteMap()\X=X
        SpriteMap()\Y=Y
        SpriteMap()\GoalX=X
        SpriteMap()\GoalY=Y
    EndIf
EndProcedure

;Make the Animation displayed again from Hide status
;Raffiche une animation cachée avec Hide
Procedure ShowAnimation(Animation.s)
    If FindMapElement(SpriteMap(),Animation)   
        SpriteMap()\Show=1
    EndIf    
EndProcedure

;make the animation disappears
;cache une animation
Procedure HideAnimation(Animation.s)
    If FindMapElement(SpriteMap(),Animation)   
        SpriteMap()\Show=0
    EndIf    
EndProcedure

;keep animation stucks on one frame
;bloque une animation sur une image
Procedure PauseAnimation(Animation.s)
    If FindMapElement(SpriteMap(),Animation)   
        SpriteMap()\pause=1
    EndIf    
EndProcedure

;resume animation from pause
;fait repartir l'animation après une pause
Procedure ResumeAnimation(Animation.s)
    If FindMapElement(SpriteMap(),Animation)   
        SpriteMap()\pause=0
    EndIf    
EndProcedure

;Sprites are supposed to be left-right oriented on spritesheet.
;Return -1 if sprite faces leftward else 1
;retourne -1 si le sprite est dirigé vers la gauche sinon 1
Procedure AnimationSensH(Animation.s)
    If FindMapElement(SpriteMap(),Animation)
        If FindMapElement(SpriteMap()\Anim(),SpriteMap()\CurrentAnimation)
            ProcedureReturn SpriteMap()\Anim()\Sprite()\FlipH
        EndIf
    EndIf
EndProcedure

;Sprites are supposed to be Bottom-Up oriented on spritesheet.
;Return -1 if sprite faces Upward else 1
;retourne -1 si le sprite est dirigé vers le haut, sinon 1
Procedure AnimationSensV(Animation.s)
    If FindMapElement(SpriteMap(),Animation)
        If FindMapElement(SpriteMap()\Anim(),SpriteMap()\CurrentAnimation)
            ProcedureReturn SpriteMap()\Anim()\Sprite()\FlipV
        EndIf
    EndIf
EndProcedure

;return x coordinate
;retourne la coordonnée X de l'animation
Procedure XAnimation(Animation.s)
    If FindMapElement(SpriteMap(),Animation)   
        ProcedureReturn SpriteMap()\X
    EndIf    
EndProcedure

;return y coordinate
;retourne la coordonnée y de l'animation
Procedure YAnimation(Animation.s)
    If FindMapElement(SpriteMap(),Animation)   
        ProcedureReturn SpriteMap()\Y
    EndIf    
EndProcedure

;return the width of the largest sprite in animation
;retourne la largeur du plus grand sprite de l'animation
Procedure AnimationWidth(Animation.s)
    If FindMapElement(SpriteMap(),Animation)   
        ProcedureReturn SpriteMap()\MaxSizeX
    EndIf 
EndProcedure

;return the height of the largest sprite in animation
;retourne la hauteur du plus grand sprite de l'animation
Procedure AnimationHeight(Animation.s)
    If FindMapElement(SpriteMap(),Animation)   
        ProcedureReturn SpriteMap()\MaxSizeY
    EndIf 
EndProcedure

Procedure AnimationScroll(Animation.s, StepX.i, StepY.i ,SubAnimation.s="")
    Protected SpriteW, SpriteH, y, Buffer, Pitch, PixelFormat, *Dest, *debut
    If FindMapElement(SpriteMap(),Animation) 
        If SubAnimation<>""
            If FindMapElement(SpriteMap()\Anim(),SubAnimation)
                ForEach SpriteMap()\Anim()\Sprite()
                    sprite=SpriteMap()\Anim()\Sprite()\Number
                    If StartDrawing(SpriteOutput(sprite))
                        SpriteW = OutputWidth(): SpriteH = OutputHeight()
                        StepX = (StepX + SpriteW) % SpriteW
                        StepY = (StepY + SpriteH) % SpriteH
                        If StepX = 0 And StepY = 0: StopDrawing(): ProcedureReturn: EndIf
                        Buffer = DrawingBuffer()
                        Pitch = DrawingBufferPitch()
                        PixelFormat = DrawingBufferPixelFormat()
                        If StepX <> 0
                            If PixelFormat & (#PB_PixelFormat_32Bits_RGB | #PB_PixelFormat_32Bits_BGR)
                                StepX <<2
                            ElseIf PixelFormat & (#PB_PixelFormat_24Bits_RGB | #PB_PixelFormat_24Bits_BGR)
                                StepX * 3
                            ElseIf PixelFormat & #PB_PixelFormat_15Bits
                                StepX <<1
                            EndIf
                            *Dest = AllocateMemory(StepX)
                            For y = 0 To SpriteH - 1
                                *debut = Buffer + Pitch * y
                                CopyMemory(*debut, *Dest, StepX)
                                CopyMemory(*debut + StepX, *debut, Pitch - StepX)
                                CopyMemory(*Dest, *debut + Pitch - StepX, StepX)
                            Next y
                            FreeMemory(*dest)
                        EndIf
                        If StepY <> 0
                            If PixelFormat & #PB_PixelFormat_ReversedY
                                StepY = SpriteH - StepY ;reverse the Y value
                            EndIf
                            *Dest = AllocateMemory(Pitch * StepY)
                            *debut = Buffer
                            CopyMemory(*debut, *Dest, Pitch * StepY)
                            CopyMemory(*debut + Pitch * StepY, *debut, Pitch * (SpriteH - StepY))
                            CopyMemory(*Dest, *debut + Pitch * (SpriteH - StepY), Pitch * StepY)
                            FreeMemory(*Dest)
                        EndIf  
                        StopDrawing()
                    EndIf
                Next
                
            EndIf
        Else
            ForEach SpriteMap()\Anim()
                ForEach SpriteMap()\Anim()\Sprite()
                    sprite=SpriteMap()\Anim()\Sprite()\Number
                    If StartDrawing(SpriteOutput(sprite))
                        SpriteW = OutputWidth(): SpriteH = OutputHeight()
                        StepX = (StepX + SpriteW) % SpriteW
                        StepY = (StepY + SpriteH) % SpriteH
                        If StepX = 0 And StepY = 0: StopDrawing(): ProcedureReturn: EndIf
                        Buffer = DrawingBuffer()
                        Pitch = DrawingBufferPitch()
                        PixelFormat = DrawingBufferPixelFormat()
                        If StepX <> 0
                            If PixelFormat & (#PB_PixelFormat_32Bits_RGB | #PB_PixelFormat_32Bits_BGR)
                                StepX <<2
                            ElseIf PixelFormat & (#PB_PixelFormat_24Bits_RGB | #PB_PixelFormat_24Bits_BGR)
                                StepX * 3
                            ElseIf PixelFormat & #PB_PixelFormat_15Bits
                                StepX <<1
                            EndIf
                            *Dest = AllocateMemory(StepX)
                            For y = 0 To SpriteH - 1
                                *debut = Buffer + Pitch * y
                                CopyMemory(*debut, *Dest, StepX)
                                CopyMemory(*debut + StepX, *debut, Pitch - StepX)
                                CopyMemory(*Dest, *debut + Pitch - StepX, StepX)
                            Next y
                            FreeMemory(*dest)
                        EndIf
                        If StepY <> 0
                            If PixelFormat & #PB_PixelFormat_ReversedY
                                StepY = SpriteH - StepY ;reverse the Y value
                            EndIf
                            *Dest = AllocateMemory(Pitch * StepY)
                            *debut = Buffer
                            CopyMemory(*debut, *Dest, Pitch * StepY)
                            CopyMemory(*debut + Pitch * StepY, *debut, Pitch * (SpriteH - StepY))
                            CopyMemory(*Dest, *debut + Pitch * (SpriteH - StepY), Pitch * StepY)
                            FreeMemory(*Dest)
                        EndIf  
                        StopDrawing()
                    EndIf
                Next
            Next
        EndIf
    EndIf
EndProcedure

Procedure FPS()
    Static FPS,Time
    FPS+1
    If ElapsedMilliseconds()>Time+60000
        Time=ElapsedMilliseconds()
        FPS=0
    EndIf
    StartDrawing(ScreenOutput())
        DrawText(0,0,Str(Fps))
    StopDrawing()
EndProcedure
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 788
; FirstLine = 362
; Folding = --24ZtD-04ru8---eV2WV----
; EnableAsm
; EnableXP