------------------------------------------------------------------------------
--                                                                          --
--                       Copyright (C) 2016, AdaCore                        --
--                                                                          --
--  Redistribution and use in source and binary forms, with or without      --
--  modification, are permitted provided that the following conditions are  --
--  met:                                                                    --
--     1. Redistributions of source code must retain the above copyright    --
--        notice, this list of conditions and the following disclaimer.     --
--     2. Redistributions in binary form must reproduce the above copyright --
--        notice, this list of conditions and the following disclaimer in   --
--        the documentation and/or other materials provided with the        --
--        distribution.                                                     --
--     3. Neither the name of the copyright holder nor the names of its     --
--        contributors may be used to endorse or promote products derived   --
--        from this software without specific prior written permission.     --
--                                                                          --
--   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS    --
--   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT      --
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR  --
--   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   --
--   HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, --
--   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT       --
--   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,  --
--   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY  --
--   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT    --
--   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE  --
--   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.   --
--                                                                          --
------------------------------------------------------------------------------

with MicroBit.Display;
with MicroBit.Time;
with Beacon;
with MicroBit.IOs; use MicroBit.IOs;
with MicroBit.Servos; use MicroBit.Servos;
with MicroBit.Buttons; use MicroBit.Buttons;
with HAL;      use HAL;


procedure Main is
   Count_value : Uint16 := 0;
   Total_Count_value : Uint16 := 0;

   subtype Servo_Pin_Id is Pin_Id range 0 .. 1;
   type Servo_Pin_State (Active : Boolean := False) is record
      case Active is
         when True => Setpoint : Servo_Set_Point;
         when False => null;
      end case;
   end record;
   type Servo_Pin_Array  is array(Servo_Pin_Id) of Servo_Pin_State;

   Servo_Pins, Cur_Servo_Pins : Servo_Pin_Array  := (others => (Active => False));
   Code : Character := ' ';
   StrCode:String := "X";
   Button_AB : Boolean;
   Starting : Boolean := False;
   bDetected : Boolean := False;
   bOutgoing : Boolean := False;
   bIsLeave : Boolean := False;
   bIsApproch : Boolean := False;
   wait_count : Uint16 := 0;

begin

   Beacon.Initialize_Radio;

   MicroBit.Display.Set_Animation_Step_Duration (120);
   Servo_Pins := (0 => (Active => True, Setpoint => 40),
                  1 => (Active => True, Setpoint => 40));
   Microbit.Display.Display("SMART ENTRY");
   Beacon.Send_Beacon_Packet(Count_value,Total_Count_value);
  -- MicroBit.Time.Delay_Ms (4000);
   Count_value := 200;
   Total_Count_value := 0;
   Microbit.Display.Display(StrCode);
   --MicroBit.Display.Set(0,0);
   --MicroBit.Display.Set(4,4);
   loop

   --   if not MicroBit.Display.Animation_In_Progress then
   --      MicroBit.Display.Display_Async ("BLE beacon  ");
         --Count_value := Count_value + 1;
   --   end if;

       --  Update PWM pulse size

      if Starting or else Cur_Servo_Pins /= Servo_Pins then
         Starting := False;
         for J in Servo_Pins'Range loop
            if Servo_Pins (J).Active then
               Go (J, Servo_Pins (J).Setpoint);
            else
               Stop (J);
            end if;
         end loop;
         Cur_Servo_Pins := Servo_Pins;
      end if;

      --  Check buttons

      --if State (Button_A) = Pressed then 5 Green
      if MicroBit.IOs.Set(5) = False and bIsApproch = False and bIsLeave = False then
         --Servo_Pins := (0 => (Active => True, Setpoint => 40),
         --               1 => (Active => True, Setpoint => 40));
         bIsApproch := True;
         StrCode := "<";
         --MicroBit.Display.Display(' ');
         --MicroBit.Display.Display ('2');
         --MicroBit.Display.Clear(0,0);
         --MicroBit.Display.Clear(4,4);

      end if;

       if MicroBit.IOs.Set(5) and bIsApproch and bIsLeave = False then --A

         StrCode := "E";
         --Count_value := 2;
         --Total_Count_value := Total_Count_value +1;
         Servo_Pins := (0 => (Active => True, Setpoint => 40),
                        1 => (Active => True, Setpoint => 112));
      end if;


      if MicroBit.IOs.Set(11) and MicroBit.IOs.Set(5) and bIsLeave then --A
         Count_value := Count_value - 1;
         Total_Count_value := Total_Count_value +1;
         Microbit.Display.Display(Total_Count_value'Image);
         bIsLeave := False;
      end if;

      if MicroBit.IOs.Set(5) = False and MicroBit.IOs.Set(11) = False and bIsApproch and bIsLeave = False then --A
         StrCode := "X";
         Servo_Pins := (0 => (Active => True, Setpoint => 40),
                        1 => (Active => True, Setpoint => 40));
         bIsApproch := False;
         bIsLeave := True;

      end if;

      if MicroBit.IOs.Set(11) = False and MicroBit.IOs.Set(5) = True and bIsApproch and bIsLeave = False then --A
         StrCode := "X";
         Servo_Pins := (0 => (Active => True, Setpoint => 40),
                        1 => (Active => True, Setpoint => 40));
         bIsApproch := False;
         bIsLeave := True;

      end if;

      if MicroBit.IOs.Set(11) and MicroBit.IOs.Set(5) and bIsApproch and bIsLeave = False and wait_count >= 30 then --A
         StrCode := "X";
         Servo_Pins := (0 => (Active => True, Setpoint => 40),
                        1 => (Active => True, Setpoint => 40));
         wait_count := 0;
         bIsApproch := False;
         bIsLeave := True;

      end if;

      if bIsApproch and bIsLeave = False then
         wait_count:= wait_count + 1;
      end if;




      Beacon.Send_Beacon_Packet(Count_value,Total_Count_value);
      Microbit.Display.Display(StrCode);
      MicroBit.Time.Delay_Ms (250);
   end loop;




end Main;

