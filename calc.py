import math

cycle_time = 50

cycle_basic_reward = 80
cycle_cheat_reward = 122

time_to_calc = 24 * 60 * 60 # How much u will farm

cycles_u_can_do = math.floor(time_to_calc / cycle_time)

standart_reward = cycles_u_can_do * cycle_basic_reward
cheat_reward = cycles_u_can_do * cycle_cheat_reward

print("="*50)
print(f"Standart: {standart_reward} Gold | In case G/C = 80")
print(f"Cheat: {cheat_reward} Gold | In case G/C = 122")
print(f"Difference: {cheat_reward-standart_reward} Gold")
print("="*50)