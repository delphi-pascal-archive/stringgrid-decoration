unit Unit2;

{
 Code de Jean_Jean 2009 et d'un internaute sur un autre site (je ne sais plus)
  dont je me suis inspir� pour le m�canisme central de ce code qui se trouve dans
  le code de l'�v�nement StringGrid1DrawCell(...) du StringGrid

  J'ai poursuivi ici Trois objectifs:
  1. Gestion de cases � cocher dans un StringGrid permettant de d�clencher des
     actions particuli�res
  2. Gestion de la taille de la fen�tre d'�dition qui a une taille limit�e
     ce qui implique une gestion du scrollbarre et des R�gions de s�lection
     des clics souris
  3. Mise en �vidence des s�lections (propri�t�s options en particulier
     l'option goRowSelect qui permet de mettre en brillance la s�lection
     d'une ligne
}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, StdCtrls, ImgList, ExtCtrls, Buttons;

type
  TForm1 = class(TForm)
    StringGrid1: TStringGrid;
    Panel1: TPanel;
    StaticText2: TStaticText;
    ListBox2: TListBox;
    StaticText1: TStaticText;
    ListBox1: TListBox;
    StaticText3: TStaticText;
    ListBox3: TListBox;
    SpeedButton1: TSpeedButton;
    ListBox4: TListBox;
    StaticText4: TStaticText;
    ImageList1: TImageList;
    procedure FormCreate(Sender: TObject);
    procedure StringGrid1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ListBox1Click(Sender: TObject);
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure StringGrid1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SpeedButton1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { D�clarations priv�es }
  public
    { D�clarations publiques }
    MaxLignes : Integer;  // Visible dans la fen�tre
    MemWidth  : Integer;  // Largeur fen�tre sans scrollBar
    NCol,NLig : integer;
    HLig,ELig : integer;

    procedure ParametreLaGrille(Const NbL,HautL,EpLig : Integer);
    procedure Update_SizeFenetre(Const aNlig,aHLig,aELig,aMaxLig : Integer);
    procedure LectureFic(Const aFic : String; aStrGrid : TStringGrid);
  end;

Const
  NomFicLog  = 'Appli.log';

var
  Form1       : TForm1;
  RegionBox   : array[0..30] of HRGN;
  Coche       : array[0..30] of boolean;
  Rep,
  ficLog      : String;
  Bitmap1,Bitmap2,Bitmap3 : TBitmap;
  BitmapIcon1,BitmapIcon2,BitmapIcon3 : TIcon;
  IconLeft,IconRight,IconWidth,IconTop,IconHeight : Integer;

implementation

{$R *.dfm}

{-------------------------------------------------------------------------------
 initialisation de la fiche
-------------------------------------------------------------------------------}
procedure TForm1.FormCreate(Sender: TObject);
var
  I     : Integer;
  PosDC : TRect;
begin

  {initialisation du r�pertoire de recherche}
  Rep    := ExtractFilePath(Application.ExeName);
  FicLog := Rep + '\'+NomFicLog;

  {Cr�ation des images}
  BitmapIcon1 := TIcon.Create;
  ImageList1.GetIcon (0,BitmapIcon1);  //case vide
  BitmapIcon2 := TIcon.Create;
  ImageList1.GetIcon (3,BitmapIcon2);  //case coch�e
  BitmapIcon3 := TIcon.Create;
  ImageList1.GetIcon (5,BitmapIcon3);  //case incochable

  Bitmap1     := TBitmap.Create;
  ImageList1.GetBitmap (2,Bitmap1);    //ligne fixe
  Bitmap2     := TBitmap.Create;
  ImageList1.GetBitmap(1,Bitmap2);     //image de fond du stringGrid

  {Boite liste du Nb de lignes de la grille}
  For i:= 1 to 9 do Listbox1.Items.Add('  '+intToStr(i));
  For i:= 10 to 26 do Listbox1.Items.Add(intToStr(i));
  ListBox1.ItemIndex := 25;
  {Boite liste du Nb de lignes visible de la fen�tre d'�dition}
  MaxLignes := 10;
  For i:= 1 to 9 do Listbox4.Items.Add('  '+intToStr(i));
  For i:= 10 to 80 do Listbox4.Items.Add(intToStr(i));
  ListBox4.ItemIndex := 9;

  {Caract�ristiques invariables du StringGrid}
  with StringGrid1 do
  begin
    ColCount     :=   3;
    FixedCols    :=   0;
    FixedRows    :=   1;
    RowCount     :=  26;
    ColWidths[0] :=  50;
    ColWidths[1] := 300;
    ColWidths[2] :=  80;
    Cells[0,0]   := 'X';
    Cells[1,0]   := 'informations';
    Cells[2,0]   := 'Taille';
  end;

  {Param�trage grille variable}
  NCol :=  3;
  NLig := 26;
  HLig := 16; // hauteur des icones des cases � cocher
  ELig :=  1; // �paisseur lignes interCellules
  ParametreLaGrille(NLig,HLig,ELig);
  Listbox1.ItemIndex := 25; // 26 lignes dans le fichier
  ListBox2.ItemIndex :=  3; // hauteur des icones des cases � cocher  = 16
  ListBox3.ItemIndex :=  1; // �paisseur lignes s�paratrices = 1

  {lecture du fichier de donn�es}
  LectureFic(Ficlog,StringGrid1);

  {initialisations des variables du fichier de donn�es}
  for I:= 0 to 30 do Coche[I]:= False;

  {Largeur fen�tre : on cherche les coordonn�es de la derni�re colonne dans un TRect}
  With StringGrid1 do
  begin
    ClientWidth := 640;
    MemWidth    := 640;
    PosDC := CellRect(ColCount - 1, 0);
    if (PosDC.Right + GridLineWidth) <> ClientWidth
    then ColWidths[ColCount-1] := ClientWidth - PosDC.Left;
  end;

  {Hauteur fen�tre. On ajoute 4 pixels inter composants probablement}
  Update_SizeFenetre(Nlig,HLig,ELig,MaxLignes);
end;

{-------------------------------------------------------------------------------
 Lib�re les Bitmap
-------------------------------------------------------------------------------}
procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  BitmapIcon1.Free;
  BitmapIcon2.Free;
  BitmapIcon3.Free;
  Bitmap1.Free;
  Bitmap2.Free;
end;

{-------------------------------------------------------------------------------
 Param�tre le dessin de la grille StringGrid1
-------------------------------------------------------------------------------}
procedure TForm1.ParametreLaGrille(Const NbL,HautL,EpLig : Integer);
begin
  with StringGrid1 do
  begin
    DefaultRowHeight := HautL;
    RowCount         := NbL + 1;
    GridLineWidth    := EpLig;
  end;
end;

{-------------------------------------------------------------------------------
 Update Taille fen�tre d'�dition
 Hauteur = f(Maxlignes Visibles,Hauteur des lignes, Epaisseur lignes S�paratrices,
             Nb de lignes scroll�es)
 Largeur = f(dimensions composants, Pr�sence scrollbar, Epaisseur lignes s�paratrices)
-------------------------------------------------------------------------------}
Procedure TForm1.Update_SizeFenetre(Const aNlig,aHLig,aELig,aMaxLig : Integer);
begin
  if aNLig > aMaxLig then
  begin
    Form1.ClientHeight := (aMaxLig + 1) * (aHLig + aELig) + Panel1.Height + 80;
    Form1.ClientWidth  := MemWidth + 22;
    StringGrid1.ScrollBars := ssVertical;
  end else
  begin
    Form1.ClientHeight := (aNLig + 1) * (aHLig + aELig) + Panel1.Height + 80;
    Form1.ClientWidth  := MemWidth;
    StringGrid1.ScrollBars := ssNone;
  end;
  ClientWidth := MemWidth + 3 * aELig; // 3 = Nb de colonnes
end;

{-------------------------------------------------------------------------------
 Lit le fichier texte Log et l'affiche dans le StringGrid
-------------------------------------------------------------------------------}
procedure TForm1.LectureFic(Const aFic : String; aStrGrid : TStringGrid);
 Var F : TextFile;
     L : Integer;
     ColB,ColC,Ligne : String;
begin
  {ouvre le fichier de maintenance et le charge dans la grille}
  assignfile(F,aFic);
  Reset(F);
  L := 1;

  while not EOF(F) do
  begin
    Readln(F, Ligne);
    {Remplissage de la Colonne 1}
    ColB := Ligne;
    aStrGrid.Cells[1,L] := Trim(ColB);
    {Remplissage de la Colonne 2 : On met � blanc certaines valeurs pour le test}
    if (L = 3) or (L = 5) or (L = 9) or (L = 15) or (L = 20)
    then ColC := ''
    else ColC := Copy(ligne,1,4);
    aStrGrid.Cells[2,L]:= ColC;
    if ColB <>'' then inc(L);
  end;

  CloseFile(F);
  aStrGrid.RowCount := L;
end;


{-------------------------------------------------------------------------------
 Gestion de la souris sur la Grille
-------------------------------------------------------------------------------}
procedure TForm1.StringGrid1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
 var
  MX,MY : Integer;
  Coord : TGridCoord;
begin
  Coord:= StringGrid1.MouseCoord(X,Y);

  {Si la ligne > 0 et la Colonne = 0 => Focus sur laligne}
  If (Coord.Y > 0) and (Coord.X = 0) then StringGrid1.Row := Coord.Y;

  {Positions X,Y de la souris sur le StringGrid}
  MX:=Mouse.CursorPos.X - StringGrid1.ClientOrigin.X;
  MY:=Mouse.CursorPos.Y - StringGrid1.ClientOrigin.Y;

  {si les coordonn�es de la souris sont �gales aux coordonn�es de la R�gion
   RegionBox[Coord.Y] => Changement du Curseur Souris}
  if PtInRegion(RegionBox[Coord.Y],MX, MY)= True
  then StringGrid1.Cursor := crHandPoint
  else StringGrid1.Cursor := crDefault;

end;

{-------------------------------------------------------------------------------
 Ajustement Nombre de lignes, Hauteur des lignes et Epaisseur des interlignes
-------------------------------------------------------------------------------}
procedure TForm1.ListBox1Click(Sender: TObject);
begin
  NLig := StrToInt(ListBox1.Items[ListBox1.ItemIndex]);
  HLig := StrToInt(ListBox2.Items[ListBox2.ItemIndex]);
  ELig := StrToInt(ListBox3.Items[ListBox3.ItemIndex]);
  MaxLignes := StrToInt(ListBox4.Items[ListBox4.ItemIndex]);
  with StringGrid1 do
  begin
    DefaultRowHeight := HLig;
    RowCount         := NLig;
    GridLineWidth    := ELig;
  end;
  ParametreLaGrille(NLig,HLig,ELig);
  Update_SizeFenetre(Nlig,HLig,ELig,MaxLignes);
end;

{-------------------------------------------------------------------------------
 Dessine les cellules du stringGrid d'�dition du fichier log
-------------------------------------------------------------------------------}
procedure TForm1.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
 var TypeIcon : TIcon;
begin
  with StringGrid1 do
  begin
    Canvas.Brush.Style := bsClear;

    {affiche la premi�re ligne}
    If ARow = 0 then
    begin
      canvas.Font.Color  := ClBlack;
      Canvas.Font.Size   := 10;
      Canvas.Font.Name   := 'Arial';
      Canvas.Font.Style  := [fsBold];
      Canvas.StretchDraw(Rect,Bitmap1);

      DrawText(Canvas.Handle, PChar(Cells[ACol ,ARow]), -1, Rect ,
               DT_CENTER or DT_NOPREFIX or DT_VCENTER or DT_SINGLELINE  );
    end else
    begin
      {position de la case � cocher}
      Rect.Left := StringGrid1.ColWidths[0] div 2;
      Rect.Left := Rect.Left - (16 div 2);
      Rect.Top  := Rect.Top + (DefaultRowHeight div 2);
      Rect.Top  := Rect.Top  - (16 div 2);

      {Cr�ation de la r�gion du CheckBox}
      IconLeft  := Rect.Left;
      IconWidth := (IconLeft + 16 ); // largeur de 16 pixels
      IconTop   := Rect.Top;
      IconHeight:= IconTop + 16;    // hauteur de 16 pixels

      RegionBox[Arow]:= CreateRectRgn(IconLeft,IconTop,IconWidth,IconHeight);

      {on grise la colonne 2 si elle est vide}
      If Cells[2,Arow]<> '' then TypeIcon := BitmapIcon1
                            else TypeIcon := BitmapIcon3;

      If (ACol=0) then
      begin
        {SI Coche[ARow]=1 alors l'image sera la coche, sinon BitampIcon3 (VIDE OU GRISE)}
        if (Coche[ARow]=True) and (Cells[2,Arow]<>'')
        then Canvas.StretchDraw(Rect,BitmapIcon2)
        else Canvas.StretchDraw(Rect,TypeIcon);
      end;
    end;

    {Ligne s�lectionn�e}
    if (gdFocused in State) then
    begin
      Rect.Left          := - StringGrid1.ColWidths[0] div 2;
      Rect.Left          := Rect.Left - (16 div 2);;
      Rect.Top           := Rect.Top - (DefaultRowHeight div 2);
      Rect.Top           := Rect.Top  + (16 div 2);

      Canvas.Font.Color  := clYellow;
      Canvas.Font.Style  := [];

      If (ACol=0)then
      begin
        Canvas.StretchDraw(Rect,Bitmap2);

        Rect.Left         := StringGrid1.ColWidths[0] div 2;
        Rect.Left         := Rect.Left - (16 div 2);
        Rect.Top          := Rect.Top + (DefaultRowHeight div 2);
        Rect.Top          := Rect.Top  - (16 div 2);

        {Si Coche[ARow]=1 alors l'image sera la coche, sinon BitampIcon3 (VIDE OU GRISE)}
        if (Coche[ARow]=True) and (Cells[2,Arow]<>'')
        then Canvas.StretchDraw(Rect,BitmapIcon2)
        else Canvas.StretchDraw(Rect,TypeIcon);
      end;
    end;
  end;{stringGrid1}

end;

{-------------------------------------------------------------------------------
 G�re les cases � cocher du stringGrid
-------------------------------------------------------------------------------}
procedure TForm1.StringGrid1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  If StringGrid1.Cursor = crHandPoint then
  if (Coche[StringGrid1.Row] = False) and (StringGrid1.Cells[2,StringGrid1.Row]<>'')
  then Coche[StringGrid1.Row]:= True
  else Coche[StringGrid1.Row]:= False;

  StringGrid1.Refresh;
end;

{-------------------------------------------------------------------------------
 D�clenche les actions associ�es aux cases coch�es
-------------------------------------------------------------------------------}
procedure TForm1.SpeedButton1Click(Sender: TObject);
const CR = #13#10;
var    i : integer;
  Chaine : String;
begin
  Chaine := 'Actions sur les items : ' + CR;
  {identification des cases coch�es}
  For i := 1 to StringGrid1.RowCount - 1 do
    if Coche[i] = true then Chaine := Chaine + 'Item N: '+inttostr(i)+': '
                                    + StringGrid1.Cells[2,i] + CR;
  if length(chaine) = length('Actions sur les items: ' + CR)
  then chaine := 'Aucune action demand�e car aucune case n''a �t� coch�e';

  showmessage(Chaine)
end;


end.
