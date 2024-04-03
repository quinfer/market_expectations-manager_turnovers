data1 <- read.csv("LLM-work/output1.csv")
#write.csv(data, "LLM-work/output1adj.csv", row.names = FALSE)
data2 <- read.csv("LLM-work/output2.csv")
data2 <- data2[,-1]
write.csv(rbind(data1,data2), "LLM-work/output_adj.csv", row.names = FALSE)
