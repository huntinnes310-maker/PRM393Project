using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Models.Entities
{
    public class MuscleExpGain
    {

        public string MuscleId { get; set; } = "";

        public string MuscleName { get; set; } = "";

        public int ExpGained { get; set; }

        public int OldLevel { get; set; }

        public int NewLevel { get; set; }

        public bool IsLevelUp { get; set; }
    }
}
