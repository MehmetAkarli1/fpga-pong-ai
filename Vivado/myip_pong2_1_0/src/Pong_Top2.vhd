-- This module is designed for 640x480 with a 25 MHz input clock.
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
 
library work;
use work.Pong_Pkg.all;
 
entity Pong_Top2 is
  generic (
    g_Video_Width : integer := 3;
    g_Total_Cols  : integer := 800;
    g_Total_Rows  : integer := 525;
    g_Active_Cols : integer := 640;
    g_Active_Rows : integer := 480
    );
  port (
    i_Clk     : in std_logic;
    --i_HSync   : in std_logic;
    --i_VSync   : in std_logic;
    
    i_Col_Count : in std_logic_vector(9 downto 0);
    i_Row_Count : in std_logic_vector(9 downto 0);
    
 
    -- Game Start Button
    i_Game_Start : in std_logic;
     
    -- Player 1 & Player 2 Controls (Controls Paddles)
    i_Paddle_Up_P1 : in std_logic;
    i_Paddle_Dn_P1 : in std_logic;
    i_Paddle_Up_P2 : in std_logic;
    i_Paddle_Dn_P2 : in std_logic;
    
    -- Ouptuts P1 & P2 paddle & ball position/direction, for calculating P2 paddle movement
    o_Paddle_Y_P1_Bot : out std_logic_vector(5 downto 0);
    o_Paddle_Y_P1_Top : out std_logic_vector(5 downto 0);
    o_Paddle_Y_P2_Bot : out std_logic_vector(5 downto 0);
    o_Paddle_Y_P2_Top : out std_logic_vector(5 downto 0);
    o_Ball_x : out std_logic_vector(5 downto 0);
    o_Ball_y : out std_logic_vector(5 downto 0);
    o_Ball_Dir_X    : out std_logic;
    o_Ball_Dir_Y    : out std_logic;
    
    -- Score output
    o_P1_Score : out std_logic_vector(c_Score_Width-1 downto 0);
    o_P2_Score : out std_logic_vector(c_Score_Width-1 downto 0);
     
    --o_HSync     : out std_logic;
    --o_VSync     : out std_logic;
    o_Red_Video : out std_logic_vector(g_Video_Width-1 downto 0);
    o_Blu_Video : out std_logic_vector(g_Video_Width-1 downto 0);
    o_Grn_Video : out std_logic_vector(g_Video_Width-1 downto 0)
    );
end entity Pong_Top2;
 
architecture rtl of Pong_Top2 is
 
  type t_SM_Main is (s_Idle, s_Running, s_P1_Wins, s_P2_Wins, s_Cleanup);
  signal r_SM_Main : t_SM_Main := s_Idle;
   
  signal w_HSync : std_logic;
  signal w_VSync : std_logic;
   
  -- Make these unsigned counters (always positive)
  signal w_Col_Count : std_logic_vector(9 downto 0);
  signal w_Row_Count : std_logic_vector(9 downto 0);
 
  -- Divided version of the Row/Col Counters.
  -- Allows us to make the board 40x30
  signal w_Col_Count_Div : std_logic_vector(5 downto 0) := (others => '0');
  signal w_Row_Count_Div : std_logic_vector(5 downto 0) := (others => '0');
 
  -- Integer representation of the above counters.
  -- Integers are easier to work with conceptually
  signal w_Col_Index : integer range 0 to 2**w_Col_Count_Div'length-1 := 0;
  signal w_Row_Index : integer range 0 to 2**w_Row_Count_Div'length-1 := 0; 
 
  signal w_Draw_Paddle_P1 : std_logic;
  signal w_Draw_Paddle_P2 : std_logic;
  signal w_Paddle_Y_P1    : std_logic_vector(5 downto 0);
  signal w_Paddle_Y_P2    : std_logic_vector(5 downto 0);
  signal w_Draw_Ball      : std_logic;
  signal w_Ball_X         : std_logic_vector(5 downto 0);
  signal w_Ball_Y         : std_logic_vector(5 downto 0);
  signal w_Ball_Dir_X     : std_logic;
  signal w_Ball_Dir_Y     : std_logic;
  signal w_Draw_Any       : std_logic;
   
  signal w_Game_Active : std_logic;
 
  signal w_Paddle_Y_P1_Top : unsigned(5 downto 0);
  signal w_Paddle_Y_P1_Bot : unsigned(5 downto 0);
  signal w_Paddle_Y_P2_Top : unsigned(5 downto 0);
  signal w_Paddle_Y_P2_Bot : unsigned(5 downto 0);
  
  signal w_P1_Score : unsigned(c_Score_Width-1 downto 0);
  signal w_P2_Score : unsigned(c_Score_Width-1 downto 0);
 
  signal r_P1_Score : integer range 0 to c_Score_Limit := 0;
  signal r_P2_Score : integer range 0 to c_Score_Limit := 0;
   
begin


--  -- Register syncs to align with output data.
--  p_Reg_Syncs : process (i_Clk) is
--  begin
--    if rising_edge(i_Clk) then
--      o_VSync <= w_VSync;
--      o_HSync <= w_HSync;
--    end if;
--  end process p_Reg_Syncs; 
    
    w_Col_Count <= i_Col_Count;
    w_Row_Count <= i_Row_Count;
 
   
  -- Drop 4 LSBs, which effectively divides by 16
  w_Col_Count_Div <= w_Col_Count(w_Col_Count'left downto 4);
  w_Row_Count_Div <= w_Row_Count(w_Row_Count'left downto 4);
 
  -- Instantiation of Paddle Control + Draw for Player 1 
  Paddle_Ctrl_P1_inst : Pong_Paddle_Ctrl generic map (
    g_Player_Paddle_X => c_Paddle_Col_Location_P1
    )
    port map (
      i_Clk           => i_Clk,
      i_Col_Count_Div => w_Col_Count_Div,
      i_Row_Count_Div => w_Row_Count_Div,
      i_Paddle_Up     => i_Paddle_Up_P1,
      i_Paddle_Dn     => i_Paddle_Dn_P1,
      o_Draw_Paddle   => w_Draw_Paddle_P1,
      o_Paddle_Y      => w_Paddle_Y_P1
      );
 
   
  -- Instantiation of Paddle Control + Draw for Player 2
  Paddle_Ctrl_P2_inst : Pong_Paddle_Ctrl
    generic map (
      g_Player_Paddle_X => c_Paddle_Col_Location_P2
      )
    port map (
      i_Clk           => i_Clk,
      i_Col_Count_Div => w_Col_Count_Div,
      i_Row_Count_Div => w_Row_Count_Div,
      i_Paddle_Up     => i_Paddle_Up_P2,
      i_Paddle_Dn     => i_Paddle_Dn_P2,
      o_Draw_Paddle   => w_Draw_Paddle_P2,
      o_Paddle_Y      => w_Paddle_Y_P2
      );
 
   
  -- Instantiation of Ball Control + Draw 
  Pong_Ball_Ctrl_inst : Pong_Ball_Ctrl
    port map (
      i_Clk           => i_Clk,
      i_Game_Active   => w_Game_Active,
      i_Col_Count_Div => w_Col_Count_Div,
      i_Row_Count_Div => w_Row_Count_Div,
      o_Draw_Ball     => w_Draw_Ball,
      o_Ball_X        => w_Ball_X,
      o_Ball_Y        => w_Ball_Y,
      o_Ball_Dir_X    => w_Ball_Dir_X,
      o_Ball_Dir_Y    => w_Ball_Dir_Y
      );
   
  -- Defines outputs for ball position
  o_Ball_x <= w_Ball_x;
  o_Ball_y <= w_Ball_y;
  o_Ball_Dir_X <= w_Ball_Dir_X;
  o_Ball_Dir_Y <= w_Ball_Dir_Y;
 
  -- Create Intermediary signals for P1 and P2 Paddle Top and Bottom positions
  w_Paddle_Y_P1_Bot <= unsigned(w_Paddle_Y_P1);
  w_Paddle_Y_P1_Top <= w_Paddle_Y_P1_Bot + to_unsigned(c_Paddle_Height, w_Paddle_Y_P1_Bot'length);
 
  w_Paddle_Y_P2_Bot <= unsigned(w_Paddle_Y_P2);
  w_Paddle_Y_P2_Top <= w_Paddle_Y_P2_Bot + to_unsigned(c_Paddle_Height, w_Paddle_Y_P2_Bot'length);
  
  -- Defines output for P2 paddle position
  o_Paddle_Y_P1_Bot <= std_logic_vector(w_Paddle_Y_P1_Bot);
  o_Paddle_Y_P1_Top <= std_logic_vector(w_Paddle_Y_P1_Top);
  o_Paddle_Y_P2_Bot <= std_logic_vector(w_Paddle_Y_P2_Bot);
  o_Paddle_Y_P2_Top <= std_logic_vector(w_Paddle_Y_P2_Top);
  
  -- Intermediary scores
  w_P1_Score <= to_unsigned(r_P1_Score, c_Score_Width);
  w_P2_Score <= to_unsigned(r_P2_Score, c_Score_Width);
  
  -- Defines output for scores
  o_P1_Score <= std_logic_vector(w_P1_Score);
  o_P2_Score <= std_logic_vector(w_P2_Score);
 
  -- Create a state machine to control the state of play
  p_SM_Main : process (i_Clk) is
  begin
    if rising_edge(i_Clk) then
      case r_SM_Main is -- Stay in this state until Game Start button is hit 
        when s_Idle =>
          if i_Game_Start = '1' then
            r_SM_Main <= s_Running;
          end if;
         
        -- Stay in this state until either player misses the ball 
        -- Can only occur when the Ball is at 0 or c_Game_Width-1 
        when s_Running =>
 
          -- Player 1's Side:
          if w_Ball_X = std_logic_vector(to_unsigned(0, w_Ball_X'length)) then
            if (unsigned(w_Ball_Y) < w_Paddle_Y_P1_Bot or unsigned(w_Ball_Y) > w_Paddle_Y_P1_Top) then
              r_SM_Main <= s_P2_Wins;
            end if;
 
          -- Player 2's Side:
          elsif w_Ball_X = std_logic_vector(to_unsigned(c_Game_Width-1, w_Ball_X'length)) then
            if (unsigned(w_Ball_Y) < w_Paddle_Y_P2_Bot or unsigned(w_Ball_Y) > w_Paddle_Y_P2_Top) then
              r_SM_Main <= s_P1_Wins; end if; end if; when s_P1_Wins =>
          if r_P1_Score = c_Score_Limit then
            r_P1_Score <= 0;
          else
            r_P1_Score <= r_P1_Score + 1;
          end if;
          r_SM_Main  <= s_Cleanup; when s_P2_Wins =>
          if r_P2_Score = c_Score_Limit then
            r_P2_Score <= 0;
          else
            r_P2_Score <= r_P2_Score + 1;
          end if;
          r_SM_Main <= s_Cleanup; when s_Cleanup =>
          r_SM_Main <= s_Idle; when others =>
          r_SM_Main <= s_Idle;
           
      end case;
    end if;
  end process p_SM_Main;
 
  -- Conditional Assignment of Game Active based on State Machine
  w_Game_Active <= '1' when r_SM_Main = s_Running else '0';
 
  w_Draw_Any <= w_Draw_Ball or w_Draw_Paddle_P1 or w_Draw_Paddle_P2;
   
  -- Assign Color outputs, only two colors, White or Black
  o_Red_Video <= (others => '1') when w_Draw_Any = '1' else (others => '0');
  o_Blu_Video <= (others => '1') when w_Draw_Any = '1' else (others => '0');
  o_Grn_Video <= (others => '1') when w_Draw_Any = '1' else (others => '0');
   
end architecture rtl;